import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case library, favourites, notes }

    let translationStore: TranslationStore

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @StateObject private var notesViewModel: NotesViewModel
    @StateObject private var libraryViewModel: LibraryViewModel

    @State private var selectedTab: Tab

    init(
        translationStore: TranslationStore,
        notesStore: NotesStore,
        progressStore: ReadingProgressStore,
        favoritesStore: FavoritesStore
    ) {
        self.translationStore = translationStore
        _ = progressStore
        _ = favoritesStore

        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesStore: notesStore))
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(translationStore: translationStore))
        _selectedTab = State(initialValue: .library)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(
                viewModel: libraryViewModel,
                openNotesTab: { selectedTab = .notes }
            )
            .tabItem {
                Label("Lexo", systemImage: "book")
            }
            .tag(Tab.library)

            FavoritesView(
                viewModel: FavoritesViewModel(favoritesStore: favoritesStore),
                openNotesTab: { selectedTab = .notes }
            )
            .tabItem {
                Label("Të preferuarat", systemImage: "heart")
            }
            .tag(Tab.favourites)

            NotesView(viewModel: notesViewModel, translationStore: translationStore)
                .tabItem {
                    Label("Shënimet", systemImage: "note.text")
                }
                .tag(Tab.notes)
        }
        .tint(Color.kuraniAccentBrand)
        .background(KuraniTheme.background.ignoresSafeArea())
    }
}

#if DEBUG
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
