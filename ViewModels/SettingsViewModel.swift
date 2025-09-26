import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var toast: LocalizedStringKey?
    @Published var isImporting: Bool = false

    private let translationStore: TranslationStore

    init(translationStore: TranslationStore) {
        self.translationStore = translationStore
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
}
