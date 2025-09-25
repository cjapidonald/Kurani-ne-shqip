import SwiftUI

struct LibraryView: View {
    struct ReaderRoute: Hashable {
        let surah: Int
        let ayah: Int?
    }

    @ObservedObject var viewModel: LibraryViewModel
    let openNotesTab: () -> Void

    @EnvironmentObject private var translationStore: TranslationStore
    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var authManager: AuthManager

    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    BrandHeader(titleKey: "tabs.library", subtitle: "library.sampleOnly")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if let lastRead = viewModel.lastRead {
                    Section(header: Text(LocalizedStringKey("library.lastread"))) {
                        Button {
                            path.append(ReaderRoute(surah: lastRead.surah, ayah: lastRead.ayah))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: NSLocalizedString("reader.title.compact", comment: "title"), lastRead.surah, translationStore.title(for: lastRead.surah)))
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                    Text(LocalizedStringKey("library.continueReading"))
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.accentBrand)
                            }
                        }
                        .listRowBackground(Color.primarySurface)
                    }
                }

                Section {
                    ForEach(viewModel.filteredSurahs) { surah in
                        NavigationLink(value: ReaderRoute(surah: surah.number, ayah: nil)) {
                            SurahRow(surah: surah)
                        }
                        .listRowBackground(Color.primarySurface)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.darkBackground)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: LocalizedStringKey("library.search.placeholder"))
            .navigationTitle(LocalizedStringKey("tabs.library"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: openNotesTab) {
                        Label(LocalizedStringKey("reader.notesButton"), systemImage: "note.text")
                    }
                }
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(surahNumber: route.surah, translationStore: translationStore, notesStore: notesStore),
                    startingAyah: route.ayah,
                    openNotesTab: openNotesTab
                )
                .environmentObject(authManager)
            }
            .onAppear {
                viewModel.refreshLastRead()
            }
        }
    }
}
