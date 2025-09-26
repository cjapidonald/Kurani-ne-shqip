import SwiftUI

@main
struct KuraniApp: App {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.shared.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.shared.client)
    @StateObject private var progressStore = ReadingProgressStore()

    init() {
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
    }

    var body: some Scene {
        WindowGroup {
            RootView(translationStore: translationStore, notesStore: notesStore, progressStore: progressStore)
                .environmentObject(translationStore)
                .environmentObject(notesStore)
                .environmentObject(authManager)
                .environmentObject(progressStore)
                .preferredColorScheme(.light)
                .task {
                    await translationStore.loadInitialData()
                    await notesStore.observeAuthChanges(authManager: authManager)
                }
        }
    }
}
