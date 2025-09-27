#if DEBUG
import Foundation
import Supabase

struct MockQuranService: QuranServicing {
    let wordsBySurah: [Int: [TranslationWord]]
    let favourites: [FavoriteViewRow]

    init() {
        let sampleWords = [
            TranslationWord(surah: 1, ayah: 1, position: 1, arabicWord: "ٱلْحَمْدُ", albanianWord: "Lavdi"),
            TranslationWord(surah: 1, ayah: 1, position: 2, arabicWord: "لِلَّهِ", albanianWord: "i takon Allahut"),
            TranslationWord(surah: 1, ayah: 1, position: 3, arabicWord: "رَبِّ", albanianWord: "Zot"),
            TranslationWord(surah: 1, ayah: 1, position: 4, arabicWord: "ٱلْعَالَمِينَ", albanianWord: "i botëve"),
            TranslationWord(surah: 1, ayah: 2, position: 1, arabicWord: "ٱلرَّحْمَٰنِ", albanianWord: "Mëshirues"),
            TranslationWord(surah: 1, ayah: 2, position: 2, arabicWord: "ٱلرَّحِيمِ", albanianWord: "Mëshirplotë"),
            TranslationWord(surah: 2, ayah: 255, position: 1, arabicWord: "ٱللَّهُ", albanianWord: "Allahu"),
            TranslationWord(surah: 2, ayah: 255, position: 2, arabicWord: "لَآ", albanianWord: "nuk"),
            TranslationWord(surah: 2, ayah: 255, position: 3, arabicWord: "إِلَٰهَ", albanianWord: "ka zot"),
            TranslationWord(surah: 2, ayah: 255, position: 4, arabicWord: "إِلَّا", albanianWord: "përveç"),
            TranslationWord(surah: 2, ayah: 255, position: 5, arabicWord: "هُوَ", albanianWord: "Atij"),
        ]

        wordsBySurah = Dictionary(grouping: sampleWords, by: { $0.surah })

        favourites = [
            FavoriteViewRow(
                id: UUID(),
                userId: UUID(),
                surah: 1,
                ayah: 1,
                createdAt: Date(),
                arabicAyahText: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَالَمِينَ",
                albanianAyahText: "Lavdi i qoftë Allahut, Zotit të botëve"
            ),
            FavoriteViewRow(
                id: UUID(),
                userId: UUID(),
                surah: 2,
                ayah: 255,
                createdAt: Date(),
                arabicAyahText: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ",
                albanianAyahText: "Allahu! Nuk ka zot tjetër përveç Atij"
            )
        ]
    }

    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        if let ayah, let words = wordsBySurah[surah]?.filter({ $0.ayah == ayah }) {
            return words
        }
        return wordsBySurah[surah] ?? []
    }

    func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String {
        let words = try await loadTranslationWords(surah: surah, ayah: ayah)
        return words.map(\.albanianWord).joined(separator: " ")
    }

    func getMyNotesForSurah(surah: Int) async throws -> [NoteRow] {
        []
    }

    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {}

    func isFavorite(surah: Int, ayah: Int) async throws -> Bool { false }

    func toggleFavorite(surah: Int, ayah: Int) async throws {}

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        favourites
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
