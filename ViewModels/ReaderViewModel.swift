import Foundation
import SwiftUI

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var surahNumber: Int
    @Published private(set) var ayahs: [Ayah] = []
    @Published var selectedAyah: Ayah?
    @Published var noteDraft: String = ""
    @Published var isNoteEditorPresented = false
    @Published var isSavingNote = false
    @Published var toast: LocalizedStringKey?
    @Published var fontScale: Double
    @Published var lineSpacingScale: Double

    private let translationStore: TranslationStore
    private let notesStore: NotesStore

    init(surahNumber: Int, translationStore: TranslationStore, notesStore: NotesStore) {
        self.surahNumber = surahNumber
        self.translationStore = translationStore
        self.notesStore = notesStore
        let storedFont = UserDefaults.standard.double(forKey: AppStorageKeys.fontScale)
        fontScale = storedFont == 0 ? 1.0 : storedFont
        let storedSpacing = UserDefaults.standard.double(forKey: AppStorageKeys.lineSpacingScale)
        lineSpacingScale = storedSpacing == 0 ? 1.0 : storedSpacing
        loadAyahs()
    }

    var surahTitle: String {
        translationStore.title(for: surahNumber)
    }

    func loadAyahs() {
        ayahs = translationStore.ayahs(for: surahNumber)
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
}
