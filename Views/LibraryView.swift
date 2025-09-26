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
    @EnvironmentObject private var progressStore: ReadingProgressStore

    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    BrandHeader(titleKey: "tabs.library", subtitle: "library.sampleOnly")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 8)
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
                                        .foregroundColor(.kuraniTextPrimary)
                                    Text(LocalizedStringKey("library.continueReading"))
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.kuraniTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.accentBrand)
                            }
                            .appleCard()
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 6)
                    }
                }

                Section {
                    ForEach(viewModel.filteredSurahs) { surah in
                        NavigationLink(value: ReaderRoute(surah: surah.number, ayah: nil)) {
                            SurahRow(
                                surah: surah,
                                progress: progressStore.progress(for: surah.number, totalAyahs: surah.ayahCount)
                            )
                                .appleCard()
                                .padding(.horizontal, 20)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(20)
            .scrollContentBackground(.hidden)
            .listRowSeparator(.hidden)
            .background(KuraniTheme.background.ignoresSafeArea())
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: LocalizedStringKey("library.search.placeholder"))
            .navigationTitle(LocalizedStringKey("tabs.library"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: openNotesTab) {
                        Label(LocalizedStringKey("reader.notesButton"), systemImage: "note.text")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                }
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(
                        surahNumber: route.surah,
                        translationStore: translationStore,
                        notesStore: notesStore,
                        progressStore: progressStore
                    ),
                    startingAyah: route.ayah,
                    openNotesTab: openNotesTab
                )
            }
            .onAppear {
                viewModel.refreshLastRead()
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
    }
}
