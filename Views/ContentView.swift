import SwiftUI

struct ContentView: View {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.client)
    @StateObject private var favoritesStore = FavoritesStore()
    @StateObject private var progressStore = ReadingProgressStore()

    var body: some View {
        RootView(
            translationStore: translationStore,
            notesStore: notesStore,
            progressStore: progressStore,
            favoritesStore: favoritesStore
        )
            .environmentObject(translationStore)
            .environmentObject(notesStore)
            .environmentObject(favoritesStore)
            .environmentObject(progressStore)
            .environmentObject(authManager)
            .preferredColorScheme(.light)
            .task {
                await translationStore.loadInitialData()
                await notesStore.observeAuthChanges(authManager: authManager)
            }
    }
}

#Preview {
    ContentView()
}
