import SwiftUI

struct NotesView: View {
    struct ReaderRoute: Hashable {
        let surah: Int
        let ayah: Int
    }

    @ObservedObject var viewModel: NotesViewModel
    let translationStore: TranslationStore

    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notesStore.isLoading {
                    VStack(spacing: 16) {
                        ProgressView(LocalizedStringKey("notes.loading"))
                            .progressViewStyle(.circular)
                            .tint(.kuraniAccentLight)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sortedSurahNumbers.isEmpty {
                    VStack(spacing: 16) {
                        BrandHeader(titleKey: "notes.title", subtitle: "notes.empty")
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            BrandHeader(titleKey: "notes.title", subtitle: "notes.openReader")
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 8)
                        }

                        ForEach(viewModel.sortedSurahNumbers, id: \.self) { surahNumber in
                            Section(header: Text(sectionTitle(for: surahNumber))) {
                                ForEach(viewModel.notes(for: surahNumber)) { note in
                                    Button {
                                        path.append(ReaderRoute(surah: note.surah, ayah: note.ayah))
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(note.text)
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(.kuraniTextPrimary)
                                                .lineLimit(3)
                                            Text(String(format: NSLocalizedString("notes.lastUpdated", comment: "updated"), formatted(date: note.updatedAt)))
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.kuraniTextSecondary)
                                        }
                                        .appleCard(cornerRadius: 20)
                                        .padding(.horizontal, 20)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 6)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .listSectionSpacing(20)
                    .scrollContentBackground(.hidden)
                    .listRowSeparator(.hidden)
                    .background(KuraniTheme.background.ignoresSafeArea())
                }
            }
            .background(KuraniTheme.background.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("notes.title"))
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(
                        surahNumber: route.surah,
                        translationStore: translationStore,
                        notesStore: notesStore,
                        favoritesStore: favoritesStore
                    ),
                    startingAyah: route.ayah,
                    openNotesTab: { path = [] }
                )
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
    }

    private func sectionTitle(for surah: Int) -> String {
        String(format: NSLocalizedString("notes.section", comment: "section"), translationStore.title(for: surah))
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FavoritesView: View {
    struct ReaderRoute: Hashable {
        let surah: Int
        let ayah: Int
    }

    @ObservedObject var viewModel: FavoritesViewModel
    let openNotesTab: () -> Void

    @EnvironmentObject private var translationStore: TranslationStore
    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.favorites.isEmpty {
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(systemName: "heart")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundStyle(Color.kuraniAccentLight)
                                .padding(.top, 48)

                            Text(LocalizedStringKey("favorites.empty"))
                                .font(.system(.body, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.kuraniTextSecondary)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, minHeight: 360)
                    }
                    .scrollDisabled(true)
                    .background(KuraniTheme.background.ignoresSafeArea())
                } else {
                    List {
                        ForEach(viewModel.favorites) { favorite in
                            Button {
                                path.append(ReaderRoute(surah: favorite.surah, ayah: favorite.ayah))
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(ayahText(for: favorite))
                                        .font(.system(.body, design: .serif))
                                        .foregroundColor(.kuraniTextPrimary)
                                        .lineLimit(4)

                                    Text(detailText(for: favorite))
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.kuraniTextSecondary)
                                }
                                .appleCard(cornerRadius: 20)
                                .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 6)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.remove(favorite)
                                    }
                                } label: {
                                    Label(LocalizedStringKey("favorites.remove"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .listRowSeparator(.hidden)
                    .listSectionSpacing(16)
                    .scrollContentBackground(.hidden)
                    .background(KuraniTheme.background.ignoresSafeArea())
                }
            }
            .navigationTitle(LocalizedStringKey("favorites.title"))
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(
                        surahNumber: route.surah,
                        translationStore: translationStore,
                        notesStore: notesStore,
                        favoritesStore: favoritesStore
                    ),
                    startingAyah: route.ayah,
                    openNotesTab: {
                        path = []
                        openNotesTab()
                    }
                )
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
    }

    private func ayahText(for favorite: FavoriteAyah) -> String {
        translationStore.ayahs(for: favorite.surah).first(where: { $0.number == favorite.ayah })?.text ?? ""
    }

    private func detailText(for favorite: FavoriteAyah) -> String {
        String(
            format: NSLocalizedString("favorites.detail", comment: "favorite metadata"),
            favorite.ayah,
            translationStore.title(for: favorite.surah)
        )
    }
}
