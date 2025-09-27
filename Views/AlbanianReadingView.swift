import SwiftUI

struct AlbanianReadingView: View {
    private struct NoteRoute: Identifiable, Hashable {
        let id: Int
    }

    private struct AlertContent: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let surah: Int
    private let quranService = QuranService()

    @EnvironmentObject private var translationStore: TranslationStore
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var totalAyahs: Int = 0
    @State private var ayahTexts: [Int: String] = [:]
    @State private var noteTexts: [Int: String] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var noteRoute: NoteRoute?
    @State private var albanianDraft: String = ""
    @State private var noteDraft: String = ""
    @State private var isSavingNote = false
    @State private var alertContent: AlertContent?

    init(surah: Int = 1) {
        self.surah = surah
    }

    var body: some View {
        NavigationStack {
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
            .navigationTitle(navigationTitle)
            .background(KuraniTheme.background.ignoresSafeArea())
            .task {
                if totalAyahs == 0 && !isLoading {
                    await loadContent()
                }
            }
            .sheet(item: $noteRoute) { route in
                AlbanianNoteEditorView(
                    ayahNumber: route.id,
                    surahNumber: surah,
                    surahTitle: navigationTitle,
                    albanianDraft: $albanianDraft,
                    noteDraft: $noteDraft,
                    isSaving: isSavingNote,
                    onCancel: { noteRoute = nil },
                    onSave: { saveNote(for: route.id) }
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
    }

    private var navigationTitle: String {
        let title = translationStore.title(for: surah)
        if title.isEmpty {
            return String(format: NSLocalizedString("Surah %d", comment: "surah title"), surah)
        }
        return title
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

            var resolvedTexts: [Int: String] = [:]
            var resolvedNotes: [Int: String] = [:]
            var missingAyahs: [Int] = []
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
                    missingAyahs.append(ayah)
                }
            }

            for ayah in missingAyahs {
                let rebuilt = try await quranService.rebuildAlbanianAyah(surah: surah, ayah: ayah)
                resolvedTexts[ayah] = rebuilt
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
        albanianDraft = ayahTexts[ayah] ?? ""
        noteDraft = noteTexts[ayah] ?? ""
        noteRoute = NoteRoute(id: ayah)
    }

    private func saveNote(for ayah: Int) {
        Task {
            await MainActor.run {
                isSavingNote = true
            }
            do {
                try await quranService.upsertMyNote(
                    surah: surah,
                    ayah: ayah,
                    albanianText: albanianDraft,
                    note: noteDraft
                )
                await MainActor.run {
                    ayahTexts[ayah] = albanianDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    noteTexts[ayah] = noteDraft
                    isSavingNote = false
                    noteRoute = nil
                }
            } catch {
                await MainActor.run {
                    isSavingNote = false
                    alertContent = AlertContent(
                        title: NSLocalizedString("Error", comment: "error"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
}

private struct AlbanianNoteEditorView: View {
    let ayahNumber: Int
    let surahNumber: Int
    let surahTitle: String
    @Binding var albanianDraft: String
    @Binding var noteDraft: String
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case albanian
        case note
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(displayedSurahTitle)
                            .font(KuraniFont.forTextStyle(.subheadline))
                            .foregroundColor(.kuraniTextSecondary)
                        Text(String(format: NSLocalizedString("Ayah %d", comment: "ayah title"), ayahNumber))
                            .font(KuraniFont.forTextStyle(.headline))
                            .foregroundColor(.kuraniTextPrimary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("Albanian Text"))
                            .font(KuraniFont.forTextStyle(.callout))
                            .foregroundColor(.kuraniTextSecondary)
                        TextEditor(text: $albanianDraft)
                            .focused($focusedField, equals: .albanian)
                            .frame(minHeight: 160)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.kuraniPrimarySurface.opacity(0.58))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.8)
                                    )
                            )
                            .foregroundColor(.kuraniTextPrimary)
                            .font(KuraniFont.forTextStyle(.body))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(LocalizedStringKey("Personal Note"))
                            .font(KuraniFont.forTextStyle(.callout))
                            .foregroundColor(.kuraniTextSecondary)
                        TextEditor(text: $noteDraft)
                            .focused($focusedField, equals: .note)
                            .frame(minHeight: 120)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.kuraniPrimarySurface.opacity(0.58))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.8)
                                    )
                            )
                            .foregroundColor(.kuraniTextPrimary)
                            .font(KuraniFont.forTextStyle(.body))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(KuraniTheme.background.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("Edit Note"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Text(LocalizedStringKey("action.cancel"))
                            .font(KuraniFont.forTextStyle(.body))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onSave) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("action.ok"))
                                .font(KuraniFont.forTextStyle(.body))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(albanianDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .tint(.kuraniAccentLight)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = .albanian
                }
            }
        }
    }
}

private extension AlbanianNoteEditorView {
    var displayedSurahTitle: String {
        let trimmed = surahTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return String(format: NSLocalizedString("Surah %d", comment: "surah title"), surahNumber)
        }
        return trimmed
    }
}
