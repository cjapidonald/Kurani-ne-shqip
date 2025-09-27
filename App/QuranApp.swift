import SwiftUI

@main
struct KuraniApp: App {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.shared.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.shared.client)
    @StateObject private var progressStore = ReadingProgressStore()
    @StateObject private var favoritesStore = FavoritesStore()

    init() {
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                translationStore: translationStore,
                notesStore: notesStore,
                progressStore: progressStore,
                favoritesStore: favoritesStore
            )
                .environmentObject(translationStore)
                .environmentObject(notesStore)
                .environmentObject(favoritesStore)
                .environmentObject(authManager)
                .environmentObject(progressStore)
                .preferredColorScheme(.light)
                .task {
                    await translationStore.loadInitialData()
                    await notesStore.observeAuthChanges(authManager: authManager)
                }
                .appStartTask()
        }
    }
}
