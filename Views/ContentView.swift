import SwiftUI

struct ContentView: View {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.shared.client)
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.shared.client)
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some View {
        RootView(translationStore: translationStore, notesStore: notesStore, favoritesStore: favoritesStore)
            .environmentObject(translationStore)
            .environmentObject(notesStore)
            .environmentObject(favoritesStore)
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
