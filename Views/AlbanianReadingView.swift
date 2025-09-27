import SwiftUI

struct AlbanianReadingView: View {
    private struct NoteEditorConfiguration: Identifiable {
        let id = UUID()
        let ayah: Int
        let albanianText: String
        let existingNote: String
    }

    private struct AlertContent: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let surah: Int
    private let quranService: QuranServicing

    @EnvironmentObject private var translationStore: TranslationStore
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var totalAyahs: Int = 0
    @State private var ayahTexts: [Int: String] = [:]
    @State private var noteTexts: [Int: String] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var noteEditor: NoteEditorConfiguration?
    @State private var alertContent: AlertContent?

    init(surah: Int = 1, quranService: QuranServicing = QuranService()) {
        self.surah = surah
        self.quranService = quranService
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                VStack(spacing: 16) {
                    Text(loadError)
                        .multilineTextAlignment(.center)
                        .font(KuraniFont.forTextStyle(.body))
                        .foregroundColor(.kuraniTextSecondary)
                    Button(action: { Task { await loadContent() } }) {
                        Text(LocalizedStringKey("Retry"))
                            .font(KuraniFont.forTextStyle(.body))
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if totalAyahs == 0 {
                            Text(LocalizedStringKey("No verses available"))
                                .font(KuraniFont.forTextStyle(.body))
                                .foregroundColor(.kuraniTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(1..<(totalAyahs + 1), id: \.self) { ayah in
                                ayahCard(for: ayah)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
        .task {
            if totalAyahs == 0 && !isLoading {
                await loadContent()
            }
        }
        .sheet(item: $noteEditor, onDismiss: { Task { await loadContent() } }) { configuration in
            NoteEditorView(
                surah: surah,
                ayah: configuration.ayah,
                initialText: configuration.albanianText,
                existingNote: configuration.existingNote,
                quranService: quranService
            )
        }
        .alert(item: $alertContent) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(LocalizedStringKey("OK")))
            )
        }
    }

    private func loadContent() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }

        do {
            let notes = try await quranService.getMyNotesForSurah(surah: surah)
            let ayahCount = await MainActor.run { translationStore.ayahCount(for: surah) }
            let maxAyahFromNotes = notes.map(\.ayah).max() ?? 0
            let finalCount = max(ayahCount, maxAyahFromNotes)

            let localAyahs = await MainActor.run { translationStore.ayahs(for: surah) }
            let localTextByAyah = Dictionary(uniqueKeysWithValues: localAyahs.map { ($0.number, $0.text) })
            var resolvedTexts: [Int: String] = [:]
            var resolvedNotes: [Int: String] = [:]
            let notesByAyah = Dictionary(uniqueKeysWithValues: notes.map { ($0.ayah, $0) })

            if finalCount > 0 {
                for ayah in 1...finalCount {
                    if let note = notesByAyah[ayah] {
                        resolvedNotes[ayah] = note.note
                        let trimmed = note.albanianText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            resolvedTexts[ayah] = trimmed
                            continue
                        }
                    }
                    if let localText = localTextByAyah[ayah], !localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        resolvedTexts[ayah] = localText
                    } else {
                        resolvedTexts[ayah] = ""
                    }
                }
            }

            await MainActor.run {
                totalAyahs = finalCount
                ayahTexts = resolvedTexts
                noteTexts = resolvedNotes
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func ayahCard(for ayah: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Pill(number: ayah)
                Spacer()
                Button(action: { toggleFavorite(for: ayah) }) {
                    Text(favoritesStore.isFavorite(surah: surah, ayah: ayah) ? "⭐️" : "☆")
                        .font(KuraniFont.forTextStyle(.title3))
                }
                .buttonStyle(.plain)

                Button(action: { openNoteEditor(for: ayah) }) {
                    Text("📝")
                        .font(KuraniFont.forTextStyle(.title3))
                }
                .buttonStyle(.plain)
            }

            Text(ayahTexts[ayah] ?? "")
                .font(KuraniFont.forTextStyle(.title3))
                .foregroundColor(.kuraniTextPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appleCard(cornerRadius: 24)
    }

    private func toggleFavorite(for ayah: Int) {
        Task {
            do {
                try await quranService.toggleFavorite(surah: surah, ayah: ayah)
                await MainActor.run {
                    favoritesStore.toggleFavorite(surah: surah, ayah: ayah)
                }
            } catch {
                await MainActor.run {
                    alertContent = AlertContent(
                        title: NSLocalizedString("Error", comment: "error"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func openNoteEditor(for ayah: Int) {
        let configuration = NoteEditorConfiguration(
            ayah: ayah,
            albanianText: ayahTexts[ayah] ?? "",
            existingNote: noteTexts[ayah] ?? ""
        )
        noteEditor = configuration
    }
}

#if DEBUG
#Preview {
    let translationStore = TranslationStore.previewStore()
    let favoritesStore = FavoritesStore()
    let authManager = AuthManager.previewManager()

    NavigationStack {
        AlbanianReadingView(surah: 1, quranService: MockQuranService())
            .environmentObject(translationStore)
            .environmentObject(favoritesStore)
            .environmentObject(authManager)
    }
}
#endif

