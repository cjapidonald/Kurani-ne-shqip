import SwiftUI

struct NotesView: View {
    struct ReaderRoute: Hashable {
        let surah: Int
        let ayah: Int
    }

    private struct NoteCreationConfiguration: Identifiable {
        let id = UUID()
        let surah: Int
        let ayah: Int
    }

    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct ExportError: Identifiable {
        let id = UUID()
        let message: LocalizedStringKey
    }

    @ObservedObject var viewModel: NotesViewModel
    let translationStore: TranslationStore

    @EnvironmentObject private var notesStore: NotesStore
    @EnvironmentObject private var progressStore: ReadingProgressStore

    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var path: [ReaderRoute] = []
    @State private var creationConfiguration: NoteCreationConfiguration?
    @State private var shareItem: ShareItem?
    @State private var exportError: ExportError?

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
                } else if viewModel.sortedSurahNumbers.isEmpty && !hasFavoriteContent {
                    VStack(spacing: 16) {
                        BrandHeader(titleKey: "notes.title", subtitle: "notes.empty")
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            BrandHeader(
                                titleKey: "notes.title",
                                subtitle: viewModel.sortedSurahNumbers.isEmpty ? "notes.empty" : "notes.openReader"
                            )
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .padding(.vertical, 8)
                        }

                        if hasFavoriteContent {
                            favoritesOverview
                        }

                        ForEach(viewModel.sortedSurahNumbers, id: \.self) { surahNumber in
                            Section(header: Text(sectionTitle(for: surahNumber))) {
                                ForEach(viewModel.notes(for: surahNumber)) { note in
                                    Button {
                                        path.append(ReaderRoute(surah: note.surah, ayah: note.ayah))
                                    } label: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(displayTitle(for: note))
                                                .font(KuraniFont.forTextStyle(.headline))
                                                .foregroundColor(.kuraniTextPrimary)
                                                .lineLimit(2)
                                            Text(note.text)
                                                .font(KuraniFont.forTextStyle(.body))
                                                .foregroundColor(.kuraniTextPrimary)
                                                .lineLimit(3)
                                            Text(String(format: NSLocalizedString("notes.lastUpdated", comment: "updated"), formatted(date: note.updatedAt)))
                                                .font(KuraniFont.forTextStyle(.caption))
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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        exportNotes()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(!hasNotes)
                    .accessibilityLabel(LocalizedStringKey("notes.export"))

                    Button {
                        openCreationSheet()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(LocalizedStringKey("action.add"))
                }
            }
            .navigationDestination(for: ReaderRoute.self) { route in
                ReaderView(
                    viewModel: ReaderViewModel(
                        surahNumber: route.surah,
                        translationStore: translationStore,
                        notesStore: notesStore,
                        progressStore: progressStore,
                        favoritesStore: favoritesStore
                    ),
                    startingAyah: route.ayah,
                    openNotesTab: { path = [] }
                )
            }
        }
        .sheet(item: $creationConfiguration) { configuration in
            AddNoteSheet(
                initialSurah: configuration.surah,
                initialAyah: configuration.ayah,
                onSave: saveNewNote,
                onDismiss: { creationConfiguration = nil }
            )
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert(item: $exportError) { error in
            Alert(
                title: Text(error.message),
                dismissButton: .default(Text(LocalizedStringKey("action.ok"))) {
                    exportError = nil
                }
            )
        }
        .background(KuraniTheme.background.ignoresSafeArea())
    }

    private var hasNotes: Bool {
        !notesStore.notes.isEmpty
    }

    private var hasFavoriteContent: Bool {
        !favoritesStore.favorites.isEmpty || !favoritesStore.folders.isEmpty
    }

    private func openCreationSheet() {
        creationConfiguration = NoteCreationConfiguration(
            surah: defaultSurahForCreation(),
            ayah: 1
        )
    }

    private func defaultSurahForCreation() -> Int {
        if let firstSurah = translationStore.surahs.first?.number {
            return firstSurah
        }
        if let firstNoteSurah = viewModel.sortedSurahNumbers.first {
            return firstNoteSurah
        }
        return 1
    }

    private func saveNewNote(surah: Int, ayah: Int, title: String, text: String) async -> Bool {
        do {
            try await notesStore.upsertNote(surah: surah, ayah: ayah, title: title, text: text)
            return true
        } catch {
            return false
        }
    }

    private func exportNotes() {
        let notes = notesStore.notes
        guard !notes.isEmpty else { return }
        do {
            let csv = csvString(from: notes)
            let url = try writeCSV(csv)
            shareItem = ShareItem(url: url)
        } catch {
            exportError = ExportError(message: LocalizedStringKey("notes.export.error"))
        }
    }

    private func writeCSV(_ csv: String) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "shenime-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data = Data(csv.utf8)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func csvString(from notes: [Note]) -> String {
        var lines: [String] = []
        lines.append(NSLocalizedString("notes.export.header", comment: "CSV header"))
        let formatter = csvDateFormatter()
        for note in notes {
            let fields = [
                csvEscape(displayTitle(for: note)),
                csvEscape(surahDisplayName(for: note.surah)),
                csvEscape(String(note.ayah)),
                csvEscape(note.text),
                csvEscape(formatter.string(from: note.updatedAt))
            ]
            let line = fields.map { "\"\($0)\"" }.joined(separator: ",")
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\"\"")
    }

    private func csvDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    private func sectionTitle(for surah: Int) -> String {
        String(format: NSLocalizedString("notes.section", comment: "section"), surahDisplayName(for: surah))
    }

    private func displayTitle(for note: Note) -> String {
        if let title = note.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        return defaultTitle(for: note.surah, ayah: note.ayah)
    }

    private func defaultTitle(for surah: Int, ayah: Int) -> String {
        let surahName = surahDisplayName(for: surah)
        return String(
            format: NSLocalizedString("notes.defaultTitle", comment: "default note title"),
            surahName,
            ayah
        )
    }

    private func surahDisplayName(for surah: Int) -> String {
        let name = translationStore.title(for: surah)
        if name.isEmpty {
            return String(format: NSLocalizedString("notes.surahNumber", comment: "surah number"), surah)
        }
        return name
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    @ViewBuilder
    private var favoritesOverview: some View {
        if !favoritesStore.favorites.isEmpty {
            favoriteAyahsSection
        }

        ForEach(favoritesStore.folders) { folder in
            favoritesFolderSection(for: folder)
        }
    }

    private var favoriteAyahsSection: some View {
        Section(header: Text(LocalizedStringKey("favorites.section.starred"))) {
            ForEach(favoritesStore.favorites) { favorite in
                Button {
                    path.append(ReaderRoute(surah: favorite.surah, ayah: favorite.ayah))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(favoriteAyahText(for: favorite))
                            .font(.system(.body, design: .serif))
                            .foregroundColor(.kuraniTextPrimary)
                            .lineLimit(4)

                        Text(favoriteDetailText(for: favorite))
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
                            favoritesStore.removeFavorite(surah: favorite.surah, ayah: favorite.ayah)
                        }
                    } label: {
                        Label(LocalizedStringKey("favorites.remove"), systemImage: "trash")
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func favoritesFolderSection(for folder: FavoriteFolder) -> some View {
        Section(header: favoritesFolderHeader(for: folder)) {
            if folder.entries.isEmpty {
                Text(LocalizedStringKey("favorites.folder.empty"))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.kuraniTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(folder.entries) { entry in
                    Button {
                        path.append(ReaderRoute(surah: entry.surah, ayah: entry.ayah))
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(favoriteAyahText(for: entry))
                                .font(.system(.body, design: .serif))
                                .foregroundColor(.kuraniTextPrimary)
                                .lineLimit(4)

                            if let note = entry.note, !note.isEmpty {
                                Text(note)
                                    .font(KuraniFont.forTextStyle(.callout))
                                    .foregroundColor(.kuraniAccentLight)
                                    .lineLimit(3)
                            }

                            Text(favoriteFolderDetailText(for: entry))
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
                                favoritesStore.removeEntry(entry, from: folder.id)
                            }
                        } label: {
                            Label(LocalizedStringKey("favorites.remove"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func favoritesFolderHeader(for folder: FavoriteFolder) -> some View {
        HStack {
            Text(folder.name)
            Spacer()
            Button {
                withAnimation {
                    favoritesStore.deleteFolder(folder.id)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.kuraniAccentLight)
            .accessibilityLabel(LocalizedStringKey("favorites.folder.delete"))
        }
    }

    private func favoriteAyahText(for favorite: FavoriteAyah) -> String {
        translationStore.ayahs(for: favorite.surah).first(where: { $0.number == favorite.ayah })?.text ?? ""
    }

    private func favoriteAyahText(for entry: FavoriteFolder.Entry) -> String {
        translationStore.ayahs(for: entry.surah).first(where: { $0.number == entry.ayah })?.text ?? ""
    }

    private func favoriteDetailText(for favorite: FavoriteAyah) -> String {
        String(
            format: NSLocalizedString("favorites.detail", comment: "favorite metadata"),
            favorite.ayah,
            translationStore.title(for: favorite.surah)
        )
    }

    private func favoriteFolderDetailText(for entry: FavoriteFolder.Entry) -> String {
        String(
            format: NSLocalizedString("favorites.detail", comment: "favorite metadata"),
            entry.ayah,
            translationStore.title(for: entry.surah)
        )
    }
}

private struct AddNoteSheet: View {
    let onSave: (Int, Int, String, String) async -> Bool
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var noteText: String = ""
    @State private var selectedSurah: Int
    @State private var selectedAyah: Int
    @State private var isSaving = false
    @State private var showError = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case body
    }

    init(
        initialSurah: Int,
        initialAyah: Int,
        onSave: @escaping (Int, Int, String, String) async -> Bool,
        onDismiss: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onDismiss = onDismiss
        _selectedSurah = State(initialValue: initialSurah)
        _selectedAyah = State(initialValue: max(initialAyah, 1))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    titleSection
                    noteSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(KuraniTheme.background.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("notes.add.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("action.cancel")) {
                        onDismiss()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("action.ok"))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .tint(.kuraniAccentLight)
            .onAppear {
                focusedField = .title
            }
            .alert(LocalizedStringKey("notes.saveError"), isPresented: $showError) {
                Button(LocalizedStringKey("action.ok")) {
                    showError = false
                }
            }
            .onDisappear {
                onDismiss()
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("notes.field.title"))
                .font(KuraniFont.forTextStyle(.subheadline))
                .foregroundColor(.kuraniTextSecondary)

            TextField(LocalizedStringKey("notes.field.placeholder.title"), text: $title)
                .focused($focusedField, equals: .title)
                .textFieldStyle(.plain)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(cardBackground())
                .foregroundColor(.kuraniTextPrimary)
                .font(KuraniFont.forTextStyle(.body))
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("notes.field.content"))
                .font(KuraniFont.forTextStyle(.subheadline))
                .foregroundColor(.kuraniTextSecondary)

            ZStack(alignment: .topLeading) {
                if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(LocalizedStringKey("notes.field.placeholder.content"))
                        .font(KuraniFont.forTextStyle(.body))
                        .foregroundColor(.kuraniTextSecondary)
                        .padding(.vertical, 22)
                        .padding(.horizontal, 22)
                }

                TextEditor(text: $noteText)
                    .focused($focusedField, equals: .body)
                    .frame(minHeight: 220)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .foregroundColor(.kuraniTextPrimary)
                    .font(KuraniFont.forTextStyle(.body))
                    .scrollContentBackground(.hidden)
            }
            .background(cardBackground())
        }
    }

    private func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.kuraniPrimarySurface.opacity(0.58))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.8)
            )
            .shadow(color: Color.kuraniPrimaryBrand.opacity(0.32), radius: 20, y: 14)
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            let success = await onSave(selectedSurah, selectedAyah, title, noteText)
            await MainActor.run {
                isSaving = false
                if success {
                    onDismiss()
                    dismiss()
                } else {
                    showError = true
                }
            }
        }
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
    @EnvironmentObject private var progressStore: ReadingProgressStore

    @State private var path: [ReaderRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.favorites.isEmpty && viewModel.folders.isEmpty {
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
                        if !viewModel.favorites.isEmpty {
                            Section(header: Text(LocalizedStringKey("favorites.section.starred"))) {
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
                            .listRowBackground(Color.clear)
                        }

                        ForEach(viewModel.folders) { folder in
                            Section(header: folderHeader(for: folder)) {
                                if folder.entries.isEmpty {
                                    Text(LocalizedStringKey("favorites.folder.empty"))
                                        .font(.system(.footnote, design: .rounded))
                                        .foregroundColor(.kuraniTextSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .listRowBackground(Color.clear)
                                } else {
                                    ForEach(folder.entries) { entry in
                                        Button {
                                            path.append(ReaderRoute(surah: entry.surah, ayah: entry.ayah))
                                        } label: {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(ayahText(for: entry))
                                                    .font(.system(.body, design: .serif))
                                                    .foregroundColor(.kuraniTextPrimary)
                                                    .lineLimit(4)

                                                if let note = entry.note, !note.isEmpty {
                                                    Text(note)
                                                        .font(KuraniFont.forTextStyle(.callout))
                                                        .foregroundColor(.kuraniAccentLight)
                                                        .lineLimit(3)
                                                }

                                                Text(folderDetailText(for: entry))
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
                                                    viewModel.remove(entry, from: folder)
                                                }
                                            } label: {
                                                Label(LocalizedStringKey("favorites.remove"), systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
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
                        progressStore: progressStore,
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

    private func ayahText(for entry: FavoriteFolder.Entry) -> String {
        translationStore.ayahs(for: entry.surah).first(where: { $0.number == entry.ayah })?.text ?? ""
    }

    private func folderDetailText(for entry: FavoriteFolder.Entry) -> String {
        String(
            format: NSLocalizedString("favorites.detail", comment: "favorite metadata"),
            entry.ayah,
            translationStore.title(for: entry.surah)
        )
    }

    @ViewBuilder
    private func folderHeader(for folder: FavoriteFolder) -> some View {
        HStack {
            Text(folder.name)
            Spacer()
            Button {
                withAnimation {
                    viewModel.delete(folder)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.kuraniAccentLight)
            .accessibilityLabel(LocalizedStringKey("favorites.folder.delete"))
        }
    }
}

