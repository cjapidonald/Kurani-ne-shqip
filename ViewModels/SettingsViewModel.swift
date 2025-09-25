import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var toast: LocalizedStringKey?
    @Published var isImporting: Bool = false

    private let translationStore: TranslationStore
    private let authManager: AuthManager

    init(translationStore: TranslationStore, authManager: AuthManager) {
        self.translationStore = translationStore
        self.authManager = authManager
    }

    var isUsingSampleTranslation: Bool {
        translationStore.isUsingSample
    }

    var isSignedIn: Bool {
        authManager.userId != nil
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

    func signOut() async {
        await authManager.signOut()
    }

    func sendMagicLink(email: String) async {
        await authManager.sendMagicLink(to: email)
        toast = LocalizedStringKey("signin.email.sent")
    }
}
