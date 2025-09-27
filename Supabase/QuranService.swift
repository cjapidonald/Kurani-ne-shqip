import Foundation
import Supabase

protocol QuranServicing {
    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord]
    func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String
    func getMyNotesForSurah(surah: Int) async throws -> [NoteRow]
    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws
    func isFavorite(surah: Int, ayah: Int) async throws -> Bool
    func toggleFavorite(surah: Int, ayah: Int) async throws
    func loadMyFavouritesView() async throws -> [FavoriteViewRow]
    func loadArabicDictionary() async throws -> [ArabicDictionaryEntry]
}

enum QuranServiceError: LocalizedError {
    case unauthenticated
    case supabase(message: String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return NSLocalizedString("signin.required", comment: "Authentication required")
        case .supabase(let message):
            return message
        }
    }
}

final class QuranService: QuranServicing {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        do {
            var query = client
                .from("translation")
                .select()
                .eq("surah", value: surah)

            if let ayah {
                query = query.eq("ayah", value: ayah)
            }

            let response: PostgrestResponse<[TranslationWord]> = try await query
                .order("ayah", ascending: true)
                .order("position", ascending: true)
                .execute()

            return response.value
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String {
        do {
            let words = try await loadTranslationWords(surah: surah, ayah: ayah)
            return words.map(\.albanianWord).joined(separator: " ")
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func getMyNotesForSurah(surah: Int) async throws -> [NoteRow] {
        do {
            let userId = try await requireAuthenticatedUserId()
            let response: PostgrestResponse<[NoteRow]> = try await client
                .from("notes")
                .select()
                .eq("surah", value: surah)
                .eq("user_id", value: userId.uuidString)
                .order("ayah", ascending: true)
                .execute()
            return response.value
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {
        struct NoteUpsertPayload: Encodable {
            let user_id: UUID
            let surah: Int
            let ayah: Int
            let albanian_text: String
            let note: String
        }

        do {
            let userId = try await requireAuthenticatedUserId()
            let payload = NoteUpsertPayload(
                user_id: userId,
                surah: surah,
                ayah: ayah,
                albanian_text: albanianText,
                note: note
            )

            _ = try await client
                .from("notes")
                .upsert([payload], onConflict: "user_id,surah,ayah")
                .execute()
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func isFavorite(surah: Int, ayah: Int) async throws -> Bool {
        do {
            let userId = try await requireAuthenticatedUserId()
            return try await isFavorite(surah: surah, ayah: ayah, userId: userId)
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func toggleFavorite(surah: Int, ayah: Int) async throws {
        struct FavoriteInsertPayload: Encodable {
            let user_id: UUID
            let surah: Int
            let ayah: Int
        }

        do {
            let userId = try await requireAuthenticatedUserId()
            if try await isFavorite(surah: surah, ayah: ayah, userId: userId) {
                _ = try await client
                    .from("favorites")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("surah", value: surah)
                    .eq("ayah", value: ayah)
                    .execute()
            } else {
                let payload = FavoriteInsertPayload(user_id: userId, surah: surah, ayah: ayah)
                _ = try await client
                    .from("favorites")
                    .insert([payload])
                    .execute()
            }
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        do {
            let userId = try await requireAuthenticatedUserId()
            let response: PostgrestResponse<[FavoriteViewRow]> = try await client
                .from("v_favorites_with_text")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("surah", ascending: true)
                .order("ayah", ascending: true)
                .execute()
            return response.value
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func loadArabicDictionary() async throws -> [ArabicDictionaryEntry] {
        do {
            let response: PostgrestResponse<[ArabicDictionaryEntry]> = try await client
                .from("arabic_dictionary")
                .select()
                .order("word", ascending: true)
                .execute()
            return response.value
        } catch {
            throw mapSupabaseError(error)
        }
    }
}

private extension QuranService {
    func requireAuthenticatedUserId() async throws -> UUID {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            throw QuranServiceError.unauthenticated
        }
    }

    func isFavorite(surah: Int, ayah: Int, userId: UUID) async throws -> Bool {
        let response: PostgrestResponse<[FavoriteRow]> = try await client
            .from("favorites")
            .select("id", count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("surah", value: surah)
            .eq("ayah", value: ayah)
            .execute()
        let count = response.count ?? 0
        return count > 0
    }

    func mapSupabaseError(_ error: Error) -> Error {
        if let quranError = error as? QuranServiceError {
            return quranError
        }
        if let postgrestError = error as? PostgrestError {
            return QuranServiceError.supabase(message: postgrestError.message)
        }
        return QuranServiceError.supabase(message: error.localizedDescription)
    }
}
