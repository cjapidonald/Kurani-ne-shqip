import SwiftUI

struct ContentView: View {
    @StateObject private var translationStore = TranslationStore()
    @StateObject private var notesStore = NotesStore(client: SupabaseClientProvider.clientIfAvailable())
    @StateObject private var authManager = AuthManager(client: SupabaseClientProvider.clientIfAvailable())
    @StateObject private var favoritesStore: FavoritesStore
    @StateObject private var progressStore = ReadingProgressStore()

    init() {
        _favoritesStore = StateObject(wrappedValue: FavoritesStore(client: SupabaseClientProvider.clientIfAvailable()))
    }

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
            .preferredColorScheme(ColorScheme.light)
            .task {
                await translationStore.loadInitialData()
                await notesStore.observeAuthChanges(authManager: authManager)
            }
    }
}

#if DEBUG
extension NotesStore {
    static func previewStore() -> NotesStore {
        NotesStore(client: SupabaseClientProvider.clientIfAvailable())
    }
}
#Preview {
    let translationStore = TranslationStore.previewStore()
    let notesStore = NotesStore.previewStore()
    let favoritesStore = FavoritesStore()
    let progressStore = ReadingProgressStore.previewStore()
    let authManager = AuthManager.previewManager()
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
}
#endif
