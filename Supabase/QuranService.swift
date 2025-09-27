import Foundation
import Supabase

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
    private let clientProvider: () throws -> SupabaseClient

    init(clientProvider: @escaping () throws -> SupabaseClient = SupabaseClientProvider.client) {
        self.clientProvider = clientProvider
    }

    convenience init(client: SupabaseClient) {
        self.init(clientProvider: { client })
    }

    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        let client = try clientProvider()
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
        let client = try clientProvider()
        do {
            let userId = try await requireAuthenticatedUserId(client: client)
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

        let client = try clientProvider()
        do {
            let userId = try await requireAuthenticatedUserId(client: client)
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
        let client = try clientProvider()
        do {
            let userId = try await requireAuthenticatedUserId(client: client)
            return try await isFavorite(surah: surah, ayah: ayah, userId: userId, client: client)
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

        let client = try clientProvider()
        do {
            let userId = try await requireAuthenticatedUserId(client: client)
            if try await isFavorite(surah: surah, ayah: ayah, userId: userId, client: client) {
                _ = try await client
                    .from("favourites")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .eq("surah", value: surah)
                    .eq("ayah", value: ayah)
                    .execute()
            } else {
                let payload = FavoriteInsertPayload(user_id: userId, surah: surah, ayah: ayah)
                _ = try await client
                    .from("favourites")
                    .insert([payload])
                    .execute()
            }
        } catch {
            throw mapSupabaseError(error)
        }
    }

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        let client = try clientProvider()
        do {
            let userId = try await requireAuthenticatedUserId(client: client)
            let response: PostgrestResponse<[FavoriteViewRow]> = try await client
                .from("v_favourites_with_text")
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
        let client = try clientProvider()
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
    func requireAuthenticatedUserId(client: SupabaseClient) async throws -> UUID {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            throw QuranServiceError.unauthenticated
        }
    }

    func isFavorite(surah: Int, ayah: Int, userId: UUID, client: SupabaseClient) async throws -> Bool {
        let response: PostgrestResponse<[FavoriteRow]> = try await client
            .from("favourites")
            .select("id", count: .exact)
            .eq("user_id", value: userId.uuidString)
            .eq("surah", value: surah)
            .eq("ayah", value: ayah)
            .execute()
        let count = response.count ?? 0
        return count > 0
    }

    func mapSupabaseError(_ error: Error) -> Error {
        if let localizedError = error as? LocalizedError {
            let description = localizedError.errorDescription ?? localizedError.localizedDescription
            return QuranServiceError.supabase(message: description)
        }
        return error
    }
}
