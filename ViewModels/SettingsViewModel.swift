import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var toast: LocalizedStringKey?

    private let progressStore: ReadingProgressStore

    init(progressStore: ReadingProgressStore) {
        self.progressStore = progressStore
    }

    func resetReadingProgress() {
        progressStore.reset()
        toast = LocalizedStringKey("settings.progress.resetSuccess")
    }
}
