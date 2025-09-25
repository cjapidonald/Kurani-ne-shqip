import SwiftUI

@main
struct KuraniApp: App {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.shared.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.shared.client)

    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some Scene {
        WindowGroup {
            RootView(translationStore: translationStore, notesStore: notesStore, authManager: authManager)
                .environmentObject(translationStore)
                .environmentObject(notesStore)
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
                .task {
                    await translationStore.loadInitialData()
                    await notesStore.observeAuthChanges(authManager: authManager)
                }
        }
    }
}
