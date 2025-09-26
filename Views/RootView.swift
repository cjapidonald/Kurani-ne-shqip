import SwiftUI

struct RootView: View {
    enum Tab { case library, favorites, notes, settings }

    @ObservedObject var translationStore: TranslationStore
    @ObservedObject var notesStore: NotesStore
 codex/add-reading-progress-bar-and-reset-button-rfxbyq
    @ObservedObject var progressStore: ReadingProgressStore

 codex/add-reading-progress-bar-and-reset-button
    @ObservedObject var progressStore: ReadingProgressStore

    @ObservedObject var favoritesStore: FavoritesStore
 main
 main

    @StateObject private var libraryViewModel: LibraryViewModel
    @StateObject private var notesViewModel: NotesViewModel
    @StateObject private var favoritesViewModel: FavoritesViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    @State private var selectedTab: Tab = .library

 codex/add-reading-progress-bar-and-reset-button-rfxbyq

 codex/add-reading-progress-bar-and-reset-button
 main
    init(translationStore: TranslationStore, notesStore: NotesStore, progressStore: ReadingProgressStore) {
        self.translationStore = translationStore
        self.notesStore = notesStore
        self.progressStore = progressStore
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(translationStore: translationStore))
        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesStore: notesStore))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(translationStore: translationStore, progressStore: progressStore))
codex/add-reading-progress-bar-and-reset-button-rfxbyq


    init(translationStore: TranslationStore, notesStore: NotesStore, favoritesStore: FavoritesStore) {
        self.translationStore = translationStore
        self.notesStore = notesStore
        self.favoritesStore = favoritesStore
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(translationStore: translationStore))
        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesStore: notesStore))
        _favoritesViewModel = StateObject(wrappedValue: FavoritesViewModel(favoritesStore: favoritesStore))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(translationStore: translationStore))
 main
 main
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(viewModel: libraryViewModel) {
                selectedTab = .notes
            }
            .background(Color.clear)
            .tabItem {
                Label(LocalizedStringKey("tabs.library"), systemImage: "book")
            }
            .tag(Tab.library)

            FavoritesView(viewModel: favoritesViewModel, openNotesTab: { selectedTab = .notes })
                .background(Color.clear)
                .tabItem {
                    Label(LocalizedStringKey("tabs.favorites"), systemImage: "heart")
                }
                .tag(Tab.favorites)

            NotesView(viewModel: notesViewModel, translationStore: translationStore)
                .background(Color.clear)
                .tabItem {
                    Label(LocalizedStringKey("tabs.notes"), systemImage: "note.text")
                }
                .tag(Tab.notes)

            SettingsView(viewModel: settingsViewModel)
                .background(Color.clear)
                .tabItem {
                    Label(LocalizedStringKey("tabs.settings"), systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .tint(Color.kuraniAccentBrand)
        .background(KuraniTheme.background.ignoresSafeArea())
    }
}
