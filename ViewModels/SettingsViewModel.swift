import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var toast: LocalizedStringKey?
    @Published var isImporting: Bool = false

    private let translationStore: TranslationStore
    private let progressStore: ReadingProgressStore

    init(translationStore: TranslationStore, progressStore: ReadingProgressStore) {
        self.translationStore = translationStore
        self.progressStore = progressStore
    }

    var isUsingSampleTranslation: Bool {
        translationStore.isUsingSample
    }

    func importTranslation(from url: URL) async {
        isImporting = true
        do {
            try await translationStore.importTranslation(from: url)
            toast = LocalizedStringKey("settings.import.success")
        } catch {
            toast = LocalizedStringKey("settings.import.invalid")
        }
        isImporting = false
    }

    func resetReadingProgress() {
        progressStore.reset()
        toast = LocalizedStringKey("settings.progress.resetSuccess")
    }
}
