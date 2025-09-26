import Foundation
import SwiftUI
import Combine

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
    private var cancellables: Set<AnyCancellable> = []

    init(surahNumber: Int, translationStore: TranslationStore, notesStore: NotesStore, progressStore: ReadingProgressStore, favoritesStore: FavoritesStore) {
        self.surahNumber = surahNumber
        self.translationStore = translationStore
        self.notesStore = notesStore
        self.progressStore = progressStore
        self.favoritesStore = favoritesStore

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
            try await notesStore.upsertNote(surah: surahNumber, ayah: selectedAyah.number, text: noteDraft)
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
        progressStore.updateHighestAyah(ayah, for: surahNumber, totalAyahs: totalAyahs)
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

    private func observeProgressChanges() {
        progressStore.$highestReadAyahBySurah
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshProgress()
            }
            .store(in: &cancellables)
    }

    private func refreshProgress() {
        highestAyahRead = progressStore.highestAyahRead(for: surahNumber)
        if totalAyahs == 0 {
            totalAyahs = translationStore.ayahCount(for: surahNumber)
        }
        readingProgress = progressStore.progress(for: surahNumber, totalAyahs: totalAyahs)
    }

    func toggleFavorite(for ayah: Ayah) {
        favoritesStore.toggleFavorite(surah: surahNumber, ayah: ayah.number)
    }

    func isFavorite(_ ayah: Ayah) -> Bool {
        favoriteAyahIds.contains(FavoriteAyah.id(for: surahNumber, ayah: ayah.number))
    }
}
