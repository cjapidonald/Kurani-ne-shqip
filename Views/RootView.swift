import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case arabic, albanian, favourites, notes }

    let translationStore: TranslationStore
    let notesStore: NotesStore
    let quranServiceFactory: () -> QuranServicing

    @StateObject private var notesViewModel: NotesViewModel

    @State private var selectedTab: Tab
    @State private var arabicSurahSelection: Int
    @State private var albanianSurahSelection: Int
    @AppStorage(AppStorageKeys.lastReadSurah) private var persistedSurah = 1

    init(
        translationStore: TranslationStore,
        notesStore: NotesStore,
        progressStore: ReadingProgressStore,
        favoritesStore: FavoritesStore,
        quranServiceFactory: @escaping () -> QuranServicing = { QuranService() }
    ) {
        self.translationStore = translationStore
        self.notesStore = notesStore
        self.quranServiceFactory = quranServiceFactory
        _ = progressStore
        _ = favoritesStore

        let storedSurah = UserDefaults.standard.integer(forKey: AppStorageKeys.lastReadSurah)
        let initialSurah = storedSurah > 0 ? storedSurah : 1

        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesStore: notesStore))
        _selectedTab = State(initialValue: .arabic)
        _arabicSurahSelection = State(initialValue: initialSurah)
        _albanianSurahSelection = State(initialValue: initialSurah)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ArabicReaderTab(
                selectedSurah: $arabicSurahSelection,
                persistedSurah: $persistedSurah,
                quranService: quranServiceFactory()
            )
            .tabItem {
                Label("Lexo (AR)", systemImage: "book.closed")
            }
            .tag(Tab.arabic)

            AlbanianReaderTab(
                selectedSurah: $albanianSurahSelection,
                persistedSurah: $persistedSurah,
                quranService: quranServiceFactory()
            )
            .tabItem {
                Label("Lexo (SQ)", systemImage: "book")
            }
            .tag(Tab.albanian)

            FavouritesView()
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

private struct ArabicReaderTab: View {
    @EnvironmentObject private var translationStore: TranslationStore
    @Binding var selectedSurah: Int
    @Binding var persistedSurah: Int
    private let quranService: QuranServicing

    init(
        selectedSurah: Binding<Int>,
        persistedSurah: Binding<Int>,
        quranService: QuranServicing = QuranService()
    ) {
        _selectedSurah = selectedSurah
        _persistedSurah = persistedSurah
        self.quranService = quranService
    }

    var body: some View {
        NavigationStack {
            ArabicReadingView(surah: selectedSurah, quranService: quranService)
                .navigationTitle(title(for: selectedSurah))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(translationStore.surahs) { surah in
                                Button {
                                    selectedSurah = surah.number
                                } label: {
                                    if surah.number == selectedSurah {
                                        Label(title(for: surah.number), systemImage: "checkmark")
                                    } else {
                                        Text(title(for: surah.number))
                                    }
                                }
                            }
                        } label: {
                            Label(LocalizedStringKey("reader.changeSurah"), systemImage: "list.number")
                        }
                        .disabled(translationStore.surahs.isEmpty)
                    }
                }
        }
        .onAppear(perform: ensureValidSelection)
        .onChange(of: translationStore.surahs) { _ in ensureValidSelection() }
        .onChange(of: selectedSurah) { newValue in
            persistedSurah = newValue
        }
    }

    private func ensureValidSelection() {
        guard let first = translationStore.surahs.first else { return }
        if !translationStore.surahs.contains(where: { $0.number == selectedSurah }) {
            selectedSurah = first.number
        }
    }

    private func title(for surah: Int) -> String {
        let title = translationStore.title(for: surah)
        if title.isEmpty {
            return String(format: NSLocalizedString("Surah %d", comment: "surah title"), surah)
        }
        return title
    }
}

private struct AlbanianReaderTab: View {
    @EnvironmentObject private var translationStore: TranslationStore
    @Binding var selectedSurah: Int
    @Binding var persistedSurah: Int
    private let quranService: QuranServicing

    init(
        selectedSurah: Binding<Int>,
        persistedSurah: Binding<Int>,
        quranService: QuranServicing = QuranService()
    ) {
        _selectedSurah = selectedSurah
        _persistedSurah = persistedSurah
        self.quranService = quranService
    }

    var body: some View {
        NavigationStack {
            AlbanianReadingView(surah: selectedSurah, quranService: quranService)
                .navigationTitle(title(for: selectedSurah))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(translationStore.surahs) { surah in
                                Button {
                                    selectedSurah = surah.number
                                } label: {
                                    if surah.number == selectedSurah {
                                        Label(title(for: surah.number), systemImage: "checkmark")
                                    } else {
                                        Text(title(for: surah.number))
                                    }
                                }
                            }
                        } label: {
                            Label(LocalizedStringKey("reader.changeSurah"), systemImage: "list.number")
                        }
                        .disabled(translationStore.surahs.isEmpty)
                    }
                }
        }
        .onAppear(perform: ensureValidSelection)
        .onChange(of: translationStore.surahs) { _ in ensureValidSelection() }
        .onChange(of: selectedSurah) { newValue in
            persistedSurah = newValue
        }
    }

    private func ensureValidSelection() {
        guard let first = translationStore.surahs.first else { return }
        if !translationStore.surahs.contains(where: { $0.number == selectedSurah }) {
            selectedSurah = first.number
        }
    }

    private func title(for surah: Int) -> String {
        let title = translationStore.title(for: surah)
        if title.isEmpty {
            return String(format: NSLocalizedString("Surah %d", comment: "surah title"), surah)
        }
        return title
    }
}

#if DEBUG
#Preview {
    let translationStore = TranslationStore.previewStore()
    let notesStore = NotesStore.previewStore()
    let favoritesStore = FavoritesStore()
    let progressStore = ReadingProgressStore.previewStore()
    let authManager = AuthManager.previewManager()
    let quranService = MockQuranService()

    RootView(
        translationStore: translationStore,
        notesStore: notesStore,
        progressStore: progressStore,
        favoritesStore: favoritesStore,
        quranServiceFactory: { quranService }
    )
    .environmentObject(translationStore)
    .environmentObject(notesStore)
    .environmentObject(favoritesStore)
    .environmentObject(progressStore)
    .environmentObject(authManager)
}
#endif
