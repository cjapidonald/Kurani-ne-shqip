import SwiftUI

struct FavouritesView: View {
    private struct Destination: Hashable {
        let surah: Int
        let ayah: Int
    }

    private let quranService: QuranServicing

    @State private var favourites: [FavoriteViewRow] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var path: [Destination] = []
    @State private var alertMessage: String?

    init(quranService: QuranServicing = QuranService()) {
        self.quranService = quranService
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let loadError {
                    VStack(spacing: 16) {
                        Text(loadError)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button(action: { Task { await loadFavourites() } }) {
                            Text(LocalizedStringKey("action.retry"))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favourites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(Color.kuraniAccentLight)
                        Text(LocalizedStringKey("favorites.empty"))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.kuraniTextSecondary)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(favourites) { favourite in
                            NavigationLink(value: Destination(surah: favourite.surah, ayah: favourite.ayah)) {
                                favouriteRow(favourite)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                    .refreshable { await loadFavourites() }
                }
            }
            .navigationTitle(LocalizedStringKey("favorites.title"))
            .navigationDestination(for: Destination.self) { destination in
                ArabicReadingView(surah: destination.surah, scrollToAyah: destination.ayah)
            }
            .task {
                if favourites.isEmpty && !isLoading {
                    await loadFavourites()
                }
            }
            .alert(
                LocalizedStringKey("favorites.error"),
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { alertMessage = nil } }
                )
            ) {
                Button(LocalizedStringKey("action.ok")) {
                    alertMessage = nil
                }
            } message: {
                if let alertMessage {
                    Text(alertMessage)
                }
            }
            .background(KuraniTheme.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private func favouriteRow(_ favourite: FavoriteViewRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let arabic = favourite.arabicAyahText, !arabic.isEmpty {
                Text(arabic)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(.kuraniTextPrimary)
            }
            if let albanian = favourite.albanianAyahText, !albanian.isEmpty {
                Text(albanian)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.kuraniTextSecondary)
            }
            Text(String(format: "S%d:%d", favourite.surah, favourite.ayah))
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.kuraniAccentLight)
        }
        .padding(.vertical, 8)
    }

    private func loadFavourites() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }

        do {
            let items = try await quranService.loadMyFavouritesView()
            await MainActor.run {
                favourites = items
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                favourites = []
                isLoading = false
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let items = offsets.map { favourites[$0] }
        favourites.remove(atOffsets: offsets)

        Task {
            await toggleFavorites(for: items)
            await loadFavourites()
        }
    }

    @MainActor
    private func toggleFavorites(for items: [FavoriteViewRow]) async {
        for item in items {
            do {
                try await quranService.toggleFavorite(surah: item.surah, ayah: item.ayah)
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
#Preview {
    let translationStore = TranslationStore.previewStore()
    let notesStore = NotesStore.previewStore()
    let favoritesStore = FavoritesStore()
    let progressStore = ReadingProgressStore.previewStore()

    return FavouritesView(quranService: MockQuranService())
        .environmentObject(translationStore)
        .environmentObject(notesStore)
        .environmentObject(favoritesStore)
        .environmentObject(progressStore)
}
#endif
