import Foundation

final class MockQuranService: QuranServicing {
    func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
        // Provide a small, deterministic set of words
        let words = [
            TranslationWord(surah: surah, ayah: 1, position: 1, arabicWord: "بِسْمِ", albanianWord: "Me"),
            TranslationWord(surah: surah, ayah: 1, position: 2, arabicWord: "اللَّهِ", albanianWord: "emrin"),
            TranslationWord(surah: surah, ayah: 1, position: 3, arabicWord: "الرَّحْمَٰنِ", albanianWord: "e"),
            TranslationWord(surah: surah, ayah: 1, position: 4, arabicWord: "الرَّحِيمِ", albanianWord: "Allahut")
        ]
        if let ayah = ayah {
            return words.filter { $0.ayah == ayah }
        }
        return words
    }

    func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String {
        // Return a canned sentence for previews
        return "[Preview] Surah \(surah), Ayah \(ayah): Tekst i rindërtuar në shqip."
    }

    func getMyNotesForSurah(surah: Int) async throws -> [NoteRow] {
        // Return an empty list in previews
        return []
    }

    func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {
        // No-op for previews
    }

    func isFavorite(surah: Int, ayah: Int) async throws -> Bool {
        // No favorites in preview by default
        return false
    }

    func toggleFavorite(surah: Int, ayah: Int) async throws {
        // No-op for previews
    }

    func loadMyFavouritesView() async throws -> [FavoriteViewRow] {
        // Return an empty list in previews
        return []
    }

    func loadArabicDictionary() async throws -> [ArabicDictionaryEntry] {
        // Provide a small set of dictionary entries for preview/testing
        return [
            ArabicDictionaryEntry(id: "1", word: "اللَّه", transliteration: "Allah", meanings: ["Zoti"], notes: nil),
            ArabicDictionaryEntry(id: "2", word: "الرَّحْمَٰن", transliteration: "Ar-Rahman", meanings: ["Mëshiruesi"], notes: nil)
        ]
    }
}
