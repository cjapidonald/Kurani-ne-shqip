#if DEBUG
import Foundation
import Supabase

struct MockQuranService: QuranServicing {
    private let service: QuranServicing?
    private let sampleData: SampleData

    init(service: QuranServicing? = MockQuranService.makeLiveService(), sampleData: SampleData = .default) {
        self.service = service
        self.sampleData = sampleData
    }

    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        if let service {
            do {
                let words = try await service.loadTranslationWords(surah: surah, ayah: ayah)
                if !words.isEmpty {
                    return words
                }
            } catch {
                // Fall back to deterministic sample data for previews.
            }
        }

        return sampleData.translationWords(for: surah, ayah: ayah)
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
            } catch {
                // Use preview sample data.
            }
        }
        return sampleData.notes(for: surah)
    }

    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {
        guard let service else { return }
        try? await service.upsertMyNote(surah: surah, ayah: ayah, albanianText: albanianText, note: note)
    }

    func isFavorite(surah: Int, ayah: Int) async throws -> Bool {
        if let service {
            do {
                return try await service.isFavorite(surah: surah, ayah: ayah)
            } catch {
                // Use preview sample data.
            }
        }
        return sampleData.isFavorite(surah: surah, ayah: ayah)
    }

    func toggleFavorite(surah: Int, ayah: Int) async throws {
        guard let service else { return }
        try? await service.toggleFavorite(surah: surah, ayah: ayah)
    }

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        if let service {
            do {
                let favourites = try await service.loadMyFavouritesView()
                if !favourites.isEmpty {
                    return favourites
                }
            } catch {
                // Use preview sample data.
            }
        }
        return sampleData.favourites
    }

    func loadArabicDictionary() async throws -> [ArabicDictionaryEntry] {
        if let service {
            do {
                let entries = try await service.loadArabicDictionary()
                if !entries.isEmpty {
                    return entries
                }
            } catch {
                // Use preview sample data.
            }
        }
        return sampleData.dictionaryEntries
    }

    private static func makeLiveService() -> QuranServicing? {
        guard let provider = try? SupabaseClientProvider() else { return nil }
        return QuranService(client: provider.client)
    }
}

private extension MockQuranService {
    struct SampleData {
        struct FavoriteKey: Hashable {
            let surah: Int
            let ayah: Int
        }

        let translationWordsBySurah: [Int: [TranslationWord]]
        let favourites: [FavoriteViewRow]
        let dictionaryEntries: [ArabicDictionaryEntry]
        let notesBySurah: [Int: [NoteRow]]
        let favoriteLookup: Set<FavoriteKey>

        static let `default`: SampleData = {
            let translationWords: [Int: [TranslationWord]] = [
                1: [
                    TranslationWord(surah: 1, ayah: 1, position: 1, arabicWord: "ٱلْحَمْدُ", albanianWord: "Lavdërimi"),
                    TranslationWord(surah: 1, ayah: 1, position: 2, arabicWord: "لِلَّهِ", albanianWord: "i takon Allahut"),
                    TranslationWord(surah: 1, ayah: 1, position: 3, arabicWord: "رَبِّ", albanianWord: "Zoti i"),
                    TranslationWord(surah: 1, ayah: 1, position: 4, arabicWord: "ٱلْعَالَمِينَ", albanianWord: "botëve"),
                    TranslationWord(surah: 1, ayah: 2, position: 1, arabicWord: "ٱلرَّحْمَٰنِ", albanianWord: "Mëshiruesit"),
                    TranslationWord(surah: 1, ayah: 2, position: 2, arabicWord: "ٱلرَّحِيمِ", albanianWord: "Mëshirëbërësit")
                ],
                2: [
                    TranslationWord(surah: 2, ayah: 255, position: 1, arabicWord: "ٱللَّهُ", albanianWord: "Allahu"),
                    TranslationWord(surah: 2, ayah: 255, position: 2, arabicWord: "لَآ إِلَٰهَ", albanianWord: "nuk ka zot"),
                    TranslationWord(surah: 2, ayah: 255, position: 3, arabicWord: "إِلَّا", albanianWord: "përveç"),
                    TranslationWord(surah: 2, ayah: 255, position: 4, arabicWord: "هُوَ", albanianWord: "Atij"),
                    TranslationWord(surah: 2, ayah: 255, position: 5, arabicWord: "ٱلْحَىُّ", albanianWord: "i Gjalli"),
                    TranslationWord(surah: 2, ayah: 255, position: 6, arabicWord: "ٱلْقَيُّومُ", albanianWord: "Mbajtësi i gjithësisë")
                ]
            ]

            let favourites: [FavoriteViewRow] = [
                FavoriteViewRow(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    userId: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                    surah: 1,
                    ayah: 1,
                    createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                    arabicAyahText: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَالَمِينَ",
                    albanianAyahText: "Lavdërimi i takon Allahut, Zotit të botëve"
                ),
                FavoriteViewRow(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    userId: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                    surah: 2,
                    ayah: 255,
                    createdAt: Date(timeIntervalSince1970: 1_700_086_400),
                    arabicAyahText: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ",
                    albanianAyahText: "Allahu – nuk ka zot tjetër përveç Tij, i Gjalli, Mbajtësi i gjithësisë"
                )
            ]

            let dictionaryEntries = [
                ArabicDictionaryEntry(
                    id: "dictionary-entry-rahma",
                    word: "رحمة",
                    transliteration: "rahme",
                    meanings: ["mëshirë", "dashamirësi"],
                    notes: "Shembull i një përkufizimi për fjalorin arab."
                ),
                ArabicDictionaryEntry(
                    id: "dictionary-entry-selam",
                    word: "سلام",
                    transliteration: "selam",
                    meanings: ["paqe", "përshëndetje"],
                    notes: nil
                )
            ]

            let notes: [Int: [NoteRow]] = [
                1: [
                    NoteRow(
                        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                        userId: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
                        surah: 1,
                        ayah: 1,
                        albanianText: "Lavdërimi i takon Allahut, Zotit të botëve",
                        note: "Kujton rëndësinë e mirënjohjes.",
                        createdAt: Date(timeIntervalSince1970: 1_699_913_600),
                        updatedAt: Date(timeIntervalSince1970: 1_699_913_600)
                    )
                ]
            ]

            let favoriteLookup = Set(favourites.map { FavoriteKey(surah: $0.surah, ayah: $0.ayah) })

            return SampleData(
                translationWordsBySurah: translationWords,
                favourites: favourites,
                dictionaryEntries: dictionaryEntries,
                notesBySurah: notes,
                favoriteLookup: favoriteLookup
            )
        }()

        func translationWords(for surah: Int, ayah: Int?) -> [TranslationWord] {
            let words = translationWordsBySurah[surah] ?? []
            guard let ayah else { return words }
            return words.filter { $0.ayah == ayah }
        }

        func notes(for surah: Int) -> [NoteRow] {
            notesBySurah[surah] ?? []
        }

        func isFavorite(surah: Int, ayah: Int) -> Bool {
            favoriteLookup.contains(FavoriteKey(surah: surah, ayah: ayah))
        }
    }
}

extension NotesStore {
    static func previewStore(client: SupabaseClient? = nil) -> NotesStore {
        let resolvedClient = client ?? (try? SupabaseClientProvider())?.client
        return NotesStore(client: resolvedClient)
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
    static func previewManager(client: SupabaseClient? = nil) -> AuthManager {
        let resolvedClient = client ?? (try? SupabaseClientProvider())?.client
        return AuthManager(client: resolvedClient)
    }
}

#endif
