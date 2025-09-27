import SwiftUI

struct ArabicReadingView: View {
    enum LanguageMode: String, CaseIterable, Identifiable {
        case arabic
        case albanian

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .arabic:
                return LocalizedStringKey("Arabic")
            case .albanian:
                return LocalizedStringKey("Albanian")
            }
        }
    }

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

    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var translationStore: TranslationStore

    @State private var ayahNumbers: [Int] = []
    @State private var wordsByAyah: [Int: [TranslationWord]] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selectedMode: LanguageMode = .arabic
    @State private var activeAlert: AlertContent?
    @State private var noteRoute: NoteRoute?
    @State private var noteDraft: String = ""
    @State private var isSavingNote = false

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
                        Button(action: { Task { await loadWords() } }) {
                            Text(LocalizedStringKey("Retry"))
                                .font(KuraniFont.forTextStyle(.body))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Picker("Mode", selection: $selectedMode) {
                                ForEach(LanguageMode.allCases) { mode in
                                    Text(mode.title)
                                        .tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            ForEach(ayahNumbers, id: \.self) { ayah in
                                ayahView(ayah)
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
                if ayahNumbers.isEmpty && !isLoading {
                    await loadWords()
                }
            }
            .navigationDestination(item: $noteRoute) { route in
                let ayahModel = ayahModel(for: route.id)
                BoundNoteEditorView(
                    ayah: ayahModel,
                    draft: $noteDraft,
                    isSaving: isSavingNote,
                    onCancel: { noteRoute = nil },
                    onSave: { saveNote(for: route.id) }
                )
            }
            .alert(item: $activeAlert) { alert in
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

    private func loadWords() async {
        await MainActor.run {
            isLoading = true
            loadError = nil
        }
        do {
            let words = try await quranService.loadTranslationWords(surah: surah, ayah: nil)
            let grouped = Dictionary(grouping: words, by: { $0.ayah })
            let sortedAyahs = grouped.keys.sorted()
            await MainActor.run {
                wordsByAyah = grouped.mapValues { $0.sorted(by: { $0.position < $1.position }) }
                ayahNumbers = sortedAyahs
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func ayahView(_ number: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Pill(number: number)
                Spacer()
                Button(action: { toggleFavorite(for: number) }) {
                    Text(favoritesStore.isFavorite(surah: surah, ayah: number) ? "⭐️" : "☆")
                        .font(KuraniFont.forTextStyle(.title3))
                }
                .buttonStyle(.plain)

                Button(action: { openNoteEditor(for: number) }) {
                    Text("📝")
                        .font(KuraniFont.forTextStyle(.title3))
                }
                .buttonStyle(.plain)
            }

            if let words = wordsByAyah[number] {
                WordWrapView(words, spacing: 8, lineSpacing: 10) { word in
                    Text(displayText(for: word))
                        .font(KuraniFont.forTextStyle(.title3))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.kuraniPrimarySurface.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.kuraniTextPrimary)
                        .onLongPressGesture {
                            showTranslation(for: word)
                        }
                }
            }
        }
        .appleCard(cornerRadius: 24)
    }

    private func displayText(for word: TranslationWord) -> String {
        switch selectedMode {
        case .arabic:
            return word.arabicWord
        case .albanian:
            return word.albanianWord
        }
    }

    private func alternateText(for word: TranslationWord) -> String {
        switch selectedMode {
        case .arabic:
            return word.albanianWord
        case .albanian:
            return word.arabicWord
        }
    }

    private func showTranslation(for word: TranslationWord) {
        activeAlert = AlertContent(title: displayText(for: word), message: alternateText(for: word))
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
                    activeAlert = AlertContent(
                        title: NSLocalizedString("Error", comment: "Error title"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func openNoteEditor(for ayah: Int) {
        noteDraft = notesStore.note(for: surah, ayah: ayah)?.text ?? ""
        noteRoute = NoteRoute(id: ayah)
    }

    private func saveNote(for ayah: Int) {
        Task {
            await MainActor.run {
                isSavingNote = true
            }
            do {
                try await notesStore.upsertNote(surah: surah, ayah: ayah, title: nil, text: noteDraft)
                await MainActor.run {
                    isSavingNote = false
                    noteRoute = nil
                }
            } catch {
                await MainActor.run {
                    isSavingNote = false
                    activeAlert = AlertContent(
                        title: NSLocalizedString("Error", comment: "Error title"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    private func ayahModel(for number: Int) -> Ayah {
        let words = wordsByAyah[number] ?? []
        let albanianText = words.map(\.albanianWord).joined(separator: " ")
        let arabicText = words.map(\.arabicWord).joined(separator: " ")
        return Ayah(number: number, text: albanianText, arabicText: arabicText)
    }
}

private struct WordWrapView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    init(_ data: Data, spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        let elements = Array(data.enumerated())

        return ZStack(alignment: .topLeading) {
            ForEach(elements, id: \.element.id) { index, element in
                content(element)
                    .alignmentGuide(.leading) { dimension in
                        if width + dimension.width > geometry.size.width {
                            width = 0
                            height -= dimension.height + lineSpacing
                        }
                        let result = width
                        if index == elements.count - 1 {
                            width = 0
                        } else {
                            width += dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { dimension in
                        let result = height
                        if index == elements.count - 1 {
                            width = 0
                            height = 0
                        }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: WordWrapHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(WordWrapHeightPreferenceKey.self) { totalHeight = $0 }
    }
}

private struct WordWrapHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
