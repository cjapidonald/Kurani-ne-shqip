import Foundation

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
