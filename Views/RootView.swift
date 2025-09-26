import SwiftUI

struct RootView: View {
    enum Tab { case library, notes, settings }

    @ObservedObject var translationStore: TranslationStore
    @ObservedObject var notesStore: NotesStore

    @StateObject private var libraryViewModel: LibraryViewModel
    @StateObject private var notesViewModel: NotesViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    @State private var selectedTab: Tab = .library

    init(translationStore: TranslationStore, notesStore: NotesStore) {
        self.translationStore = translationStore
        self.notesStore = notesStore
        _libraryViewModel = StateObject(wrappedValue: LibraryViewModel(translationStore: translationStore))
        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesStore: notesStore))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(translationStore: translationStore))
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
