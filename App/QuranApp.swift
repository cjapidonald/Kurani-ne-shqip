import SwiftUI

@main
struct KuraniApp: App {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.shared.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.shared.client)
 codex/add-reading-progress-bar-and-reset-button-rfxbyq
    @StateObject private var progressStore = ReadingProgressStore()

codex/add-reading-progress-bar-and-reset-button
    @StateObject private var progressStore = ReadingProgressStore()

    @StateObject private var favoritesStore = FavoritesStore()
 main
 main

    init() {
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.kuraniTextPrimary)]
    }

    var body: some Scene {
        WindowGroup {
 codex/add-reading-progress-bar-and-reset-button-rfxbyq
            RootView(translationStore: translationStore, notesStore: notesStore, progressStore: progressStore)

codex/add-reading-progress-bar-and-reset-button
            RootView(translationStore: translationStore, notesStore: notesStore, progressStore: progressStore)

            RootView(translationStore: translationStore, notesStore: notesStore, favoritesStore: favoritesStore)
 main
 main
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
        }
    }
}
