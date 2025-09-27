#if DEBUG
import Foundation
import Supabase

struct MockQuranService: QuranServicing {
    private static let previewClient: SupabaseClient? = {
        guard let url = URL(string: "https://preview.supabase.co") else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: "preview-key")
    }()

    private let service: QuranServicing?
    private let placeholderWords: [Int: [TranslationWord]]
    private let placeholderFavourites: [FavoriteViewRow]
    private let placeholderDictionary: [ArabicDictionaryEntry]

    init(client: SupabaseClient? = MockQuranService.previewClient) {
        if let client {
            service = QuranService(client: client)
        } else {
            service = nil
        }

        let sampleWords = [
            TranslationWord(surah: 1, ayah: 1, position: 1, arabicWord: "مِثال", albanianWord: "Shembull"),
            TranslationWord(surah: 1, ayah: 1, position: 2, arabicWord: "كَلِمَة", albanianWord: "fjalë"),
            TranslationWord(surah: 1, ayah: 1, position: 3, arabicWord: "مُشْتَرَكة", albanianWord: "e përbashkët"),
            TranslationWord(surah: 1, ayah: 2, position: 1, arabicWord: "نَصّ", albanianWord: "tekst"),
            TranslationWord(surah: 2, ayah: 255, position: 1, arabicWord: "مَعْرِفَة", albanianWord: "dituri"),
            TranslationWord(surah: 2, ayah: 255, position: 2, arabicWord: "حِكْمَة", albanianWord: "urtësi")
        ]

        placeholderWords = Dictionary(grouping: sampleWords, by: { $0.surah })

        placeholderFavourites = [
            FavoriteViewRow(
                id: UUID(),
                userId: UUID(),
                surah: 1,
                ayah: 1,
                createdAt: Date(),
                arabicAyahText: "Tekst demonstrues arab.",
                albanianAyahText: "Tekst demonstrues në shqip."
            ),
            FavoriteViewRow(
                id: UUID(),
                userId: UUID(),
                surah: 2,
                ayah: 255,
                createdAt: Date(),
                arabicAyahText: "Shembull i dytë arab.",
                albanianAyahText: "Shembull i dytë në shqip."
            )
        ]

        placeholderDictionary = [
            ArabicDictionaryEntry(
                id: UUID().uuidString,
                word: "علم",
                transliteration: "ilm",
                meanings: ["dituri", "njohuri"],
                notes: "Shembull demonstrues i përkthimit."
            ),
            ArabicDictionaryEntry(
                id: UUID().uuidString,
                word: "سلام",
                transliteration: "selam",
                meanings: ["paqe", "përshëndetje"],
                notes: nil
            )
        ]
    }

    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        if let service {
            do {
                let words = try await service.loadTranslationWords(surah: surah, ayah: ayah)
                if !words.isEmpty {
                    return words
                }
            } catch {
                // Fall back to placeholders if the preview client cannot reach Supabase.
            }
        }

        let words = placeholderWords[surah] ?? []
        if let ayah {
            return words.filter { $0.ayah == ayah }
        }
        return words
    }

    func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String {
        let words = try await loadTranslationWords(surah: surah, ayah: ayah)
        guard !words.isEmpty else { return "Tekst demonstrues" }
        return words.map(\.albanianWord).joined(separator: " ")
    }

    func getMyNotesForSurah(surah: Int) async throws -> [NoteRow] {
        if let service {
            do {
                return try await service.getMyNotesForSurah(surah: surah)
            } catch {}
        }
        return []
    }

    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {
        if let service {
            try? await service.upsertMyNote(surah: surah, ayah: ayah, albanianText: albanianText, note: note)
        }
    }

    func isFavorite(surah: Int, ayah: Int) async throws -> Bool {
        if let service {
            do {
                return try await service.isFavorite(surah: surah, ayah: ayah)
            } catch {}
        }
        return false
    }

    func toggleFavorite(surah: Int, ayah: Int) async throws {
        if let service {
            try? await service.toggleFavorite(surah: surah, ayah: ayah)
        }
    }

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        if let service {
            do {
                let favourites = try await service.loadMyFavouritesView()
                if !favourites.isEmpty {
                    return favourites
                }
            } catch {}
        }
        return placeholderFavourites
    }

    func loadArabicDictionary() async throws -> [ArabicDictionaryEntry] {
        if let service {
            do {
                let entries = try await service.loadArabicDictionary()
                if !entries.isEmpty {
                    return entries
                }
            } catch {}
        }
        return placeholderDictionary
    }
}

extension NotesStore {
    static func previewStore() -> NotesStore {
        let url = URL(string: "https://preview.supabase.co")!
        let client = SupabaseClient(supabaseURL: url, supabaseKey: "preview-key")
        let store = NotesStore(client: client)
        return store
    }
}

extension ReadingProgressStore {
    static func previewStore() -> ReadingProgressStore {
        let defaults = UserDefaults(suiteName: "preview.reading.progress") ?? .standard
        let store = ReadingProgressStore(userDefaults: defaults)
        store.updateHighestAyah(1, for: 1, totalAyahs: 7)
        store.updateHighestAyah(50, for: 2, totalAyahs: 286)
        return store
    }
}

extension AuthManager {
    static func previewManager() -> AuthManager {
        let url = URL(string: "https://preview.supabase.co")!
        let client = SupabaseClient(supabaseURL: url, supabaseKey: "preview-key")
        return AuthManager(client: client)
    }
}

#endif
