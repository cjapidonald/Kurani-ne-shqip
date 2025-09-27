import Foundation
import SwiftUI
import Combine
import Supabase

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var surahNumber: Int
    @Published private(set) var ayahs: [Ayah] = []
    @Published private(set) var totalAyahs: Int = 0
    @Published private(set) var highestAyahRead: Int = 0
    @Published private(set) var readingProgress: Double = 0
    @Published var selectedAyah: Ayah?
    @Published var noteDraft: String = ""
    @Published var isNoteEditorPresented = false
    @Published var isSavingNote = false
    @Published var toast: LocalizedStringKey?
    @Published var fontScale: Double
    @Published var lineSpacingScale: Double
    @Published private(set) var favoriteAyahIds: Set<FavoriteAyah.ID> = []

    private let translationStore: TranslationStore
    private let notesStore: NotesStore
    private let progressStore: ReadingProgressStore
    private let favoritesStore: FavoritesStore
    private let quranService: QuranServicing?
    private let readingProgressStore: ReadingProgressStore
    private var cancellables: Set<AnyCancellable> = []

    init(
        surahNumber: Int,
        translationStore: TranslationStore,
        notesStore: NotesStore,
        progressStore: ReadingProgressStore,
        favoritesStore: FavoritesStore,
        quranService: QuranServicing? = ReaderViewModel.makeQuranServiceIfAvailable()
    ) {
        self.surahNumber = surahNumber
        self.translationStore = translationStore
        self.notesStore = notesStore
        self.progressStore = progressStore
        self.favoritesStore = favoritesStore
        self.readingProgressStore = progressStore
        self.quranService = quranService

        let storedFont = UserDefaults.standard.double(forKey: AppStorageKeys.fontScale)
        fontScale = storedFont == 0 ? 1.0 : storedFont
        let storedSpacing = UserDefaults.standard.double(forKey: AppStorageKeys.lineSpacingScale)
        lineSpacingScale = storedSpacing == 0 ? 1.0 : storedSpacing

        loadAyahs()
        observeProgressChanges()
        refreshProgress()

        favoriteAyahIds = Set(favoritesStore.favorites.map { $0.id })
        favoritesStore.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favorites in
                self?.favoriteAyahIds = Set(favorites.map { $0.id })
            }
            .store(in: &cancellables)
    }

    var surahTitle: String {
        translationStore.title(for: surahNumber)
    }

    var progressDescription: String {
        String(format: NSLocalizedString("reader.progress", comment: "progress"), highestAyahRead, totalAyahs)
    }

    var progressPercentageString: String {
        let percentage = Int(round(readingProgress * 100))
        return "\(percentage)%"
    }

    func loadAyahs() {
        ayahs = translationStore.ayahs(for: surahNumber)
        totalAyahs = translationStore.ayahCount(for: surahNumber)
        Task { await translationStore.ensureArabicText(for: surahNumber, prefetchNextSurahCount: 1) }
        refreshProgress()
    }

    func note(for ayah: Ayah) -> Note? {
        notesStore.note(for: surahNumber, ayah: ayah.number)
    }

    func openNoteEditor(for ayah: Ayah) {
        selectedAyah = ayah
        noteDraft = note(for: ayah)?.text ?? ""
        isNoteEditorPresented = true
    }

    func saveNote() async {
        guard let selectedAyah else { return }
        isSavingNote = true
        defer { isSavingNote = false }
        do {
            let title = resolvedTitle(for: selectedAyah)
            try await notesStore.upsertNote(surah: surahNumber, ayah: selectedAyah.number, title: title, text: noteDraft)
            favoritesStore.updateNoteSnapshot(for: surahNumber, ayah: selectedAyah.number, note: noteDraft)
            Haptics.success()
            toast = LocalizedStringKey("reader.note.saved")
            isNoteEditorPresented = false
        } catch {
            toast = LocalizedStringKey("toast.error")
        }
    }

    func updateLastRead(ayah: Int) {
        UserDefaults.standard.set(surahNumber, forKey: AppStorageKeys.lastReadSurah)
        UserDefaults.standard.set(ayah, forKey: AppStorageKeys.lastReadAyah)
        readingProgressStore.updateHighestAyah(ayah, for: surahNumber, totalAyahs: totalAyahs)
        refreshProgress()
    }

    func increaseFont() {
        fontScale = min(fontScale + 0.1, 1.6)
        UserDefaults.standard.set(fontScale, forKey: AppStorageKeys.fontScale)
    }

    func decreaseFont() {
        fontScale = max(fontScale - 0.1, 0.7)
        UserDefaults.standard.set(fontScale, forKey: AppStorageKeys.fontScale)
    }

    func increaseLineSpacing() {
        lineSpacingScale = min(lineSpacingScale + 0.1, 2.0)
        UserDefaults.standard.set(lineSpacingScale, forKey: AppStorageKeys.lineSpacingScale)
    }

    func decreaseLineSpacing() {
        lineSpacingScale = max(lineSpacingScale - 0.1, 0.8)
        UserDefaults.standard.set(lineSpacingScale, forKey: AppStorageKeys.lineSpacingScale)
    }

    func toggleFavoriteStatus(for ayah: Ayah) {
        Task { await toggleFavorite(for: ayah) }
    }

    func isFavoriteAyah(_ ayah: Ayah) -> Bool {
        favoriteAyahIds.contains(FavoriteAyah.id(for: surahNumber, ayah: ayah.number))
    }

    func translationWords(for ayah: Ayah) async throws -> [TranslationWord] {
        try await translationStore.translationWords(for: surahNumber, ayah: ayah.number)
    }

    func translationWord(for ayah: Ayah, at index: Int) async throws -> TranslationWord? {
        let words = try await translationWords(for: ayah)
        guard index >= 0, index < words.count else { return nil }
        return words[index]
    }

    private func resolvedTitle(for ayah: Ayah) -> String {
        if let existing = note(for: ayah)?.title?.trimmingCharacters(in: .whitespacesAndNewlines), !existing.isEmpty {
            return existing
        }
        return defaultTitle(for: ayah)
    }

    private func defaultTitle(for ayah: Ayah) -> String {
        let surahName = translationStore.title(for: surahNumber)
        let localizedSurah = surahName.isEmpty
            ? String(format: NSLocalizedString("notes.surahNumber", comment: "surah number"), surahNumber)
            : surahName
        return String(
            format: NSLocalizedString("notes.defaultTitle", comment: "default note title"),
            localizedSurah,
            ayah.number
        )
    }

    private func observeProgressChanges() {
        readingProgressStore.$highestReadAyahBySurah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshProgress()
            }
            .store(in: &cancellables)
    }

    private func refreshProgress() {
        highestAyahRead = readingProgressStore.highestAyahRead(for: surahNumber)
        if totalAyahs == 0 {
            totalAyahs = translationStore.ayahCount(for: surahNumber)
        }
        readingProgress = readingProgressStore.progress(for: surahNumber, totalAyahs: totalAyahs)
    }

    private func toggleFavorite(for ayah: Ayah) async {
        let originalState = favoritesStore.isFavorite(surah: surahNumber, ayah: ayah.number)
        let originalFavorite = favoritesStore.favorites.first { $0.surah == surahNumber && $0.ayah == ayah.number }

        guard let quranService else {
            favoritesStore.toggleFavorite(surah: surahNumber, ayah: ayah.number)
            return
        }

        do {
            try await quranService.toggleFavorite(surah: surahNumber, ayah: ayah.number)
            let isFavorite = try await quranService.isFavorite(surah: surahNumber, ayah: ayah.number)
            favoritesStore.setFavorite(surah: surahNumber, ayah: ayah.number, isFavorite: isFavorite)
        } catch {
            favoritesStore.setFavorite(
                surah: surahNumber,
                ayah: ayah.number,
                isFavorite: originalState,
                addedAt: originalFavorite?.addedAt ?? Date()
            )
            toast = LocalizedStringKey("toast.error")
        }
    }

    func isFavorite(_ ayah: Ayah) -> Bool {
        favoriteAyahIds.contains(FavoriteAyah.id(for: surahNumber, ayah: ayah.number))
    }

    private static func makeQuranServiceIfAvailable() -> QuranServicing? {
        guard let client = SupabaseClientProvider.clientIfAvailable() else { return nil }
        return QuranService(client: client)
    }
}
