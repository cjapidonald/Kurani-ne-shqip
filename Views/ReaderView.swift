import SwiftUI
import UIKit

struct ReaderView: View {
    @ObservedObject var viewModel: ReaderViewModel
    let startingAyah: Int?
    let openNotesTab: () -> Void


    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(AppStorageKeys.showArabicText) private var showArabicText = false
    @AppStorage(AppStorageKeys.showAlbanianText) private var showAlbanianText = true


    @State private var selectedAyahForActions: Ayah?
    @State private var showingActions = false
    @State private var shareText: String = ""
    @State private var showingShareSheet = false
    @State private var showToast = false
    @State private var isChromeHidden = false
    @State private var selectedDictionaryEntry: ArabicDictionaryEntry?
    @State private var pendingDictionaryWord: String?
    @State private var fullscreenControlsVisible = false
    @State private var fullscreenHideWorkItem: DispatchWorkItem?

    private let noteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let fullscreenTapZoneHeightTop: CGFloat = 60
    private let fullscreenTapZoneHeightBottom: CGFloat = 96

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.ayahs) { ayah in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Button {
                                    selectedAyahForActions = ayah
                                    showingActions = true
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        Pill(number: ayah.number)
                                        if viewModel.note(for: ayah) != nil {
                                            NoteMarker()
                                                .offset(x: 8, y: -8)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 6) {
                                    if showAlbanianText {
                                        Text(ayah.text)
                                            .font(KuraniFont.size(18 * viewModel.fontScale, relativeTo: .body))
                                            .foregroundColor(.kuraniTextPrimary)
                                            .lineSpacing(4 * viewModel.lineSpacingScale)
                                            .contextMenu {
                                                Button(LocalizedStringKey("reader.addToNotes")) {
                                                    openNoteEditor(for: ayah)
                                                }
                                                Button(LocalizedStringKey("action.copy")) {
                                                    copyAyah(ayah)
                                                }
                                                Button(LocalizedStringKey("action.share")) {
                                                    shareAyah(ayah)
                                                }
                                                Button("PYET CHATGPT") {
                                                    askChatGPT(about: ayah)
                                                }
                                            }
                                            .onTapGesture {
                                                openNoteEditor(for: ayah)
                                            }
                                    }

                                    if showArabicText, let arabic = ayah.arabicText {
                                        ArabicSelectableTextView(
                                            text: arabic,
                                            fontScale: viewModel.fontScale,
                                            lineSpacingScale: viewModel.lineSpacingScale,
                                            onSelection: handleDictionarySelection
                                        )
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                Spacer(minLength: 12)

                                Button {
                                    viewModel.toggleFavoriteStatus(for: ayah)
                                } label: {
                                    let isFavorite = viewModel.isFavoriteAyah(ayah)
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(isFavorite ? Color.kuraniAccentBrand : Color.kuraniAccentLight.opacity(0.8))
                                        .accessibilityHidden(true)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(viewModel.isFavoriteAyah(ayah) ? LocalizedStringKey("reader.favorite.remove") : LocalizedStringKey("reader.favorite.add"))
                            }

                            if let note = viewModel.note(for: ayah) {
                                let formattedDate = noteFormatter.string(from: note.updatedAt)
                                let bannerText = String(
                                    format: NSLocalizedString("reader.noteBanner", comment: "banner"),
                                    formattedDate
                                )

                                HStack {
                                    Image(systemName: "pencil.and.outline")
                                        .foregroundStyle(Color.kuraniAccentLight)
                                    Text(bannerText)
                                        .font(KuraniFont.forTextStyle(.caption))
                                        .foregroundColor(.kuraniTextSecondary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.kuraniPrimarySurface.opacity(0.68))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.6)
                                        )
                                )
                            }
                        }
                        .appleCard(cornerRadius: 22)
                        .padding(.horizontal, 16)
                        .id(ayah.number)
                        .onAppear {
                            viewModel.updateLastRead(ayah: ayah.number)
                        }
                    }
                }
                .padding(.bottom, 56)
            }
            .background(KuraniTheme.background.ignoresSafeArea())
            .toolbarBackground(Color.kuraniDarkBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ReaderProgressTitle(title: viewModel.surahTitle, percentage: viewModel.progressPercentageString)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isChromeHidden.toggle()
                        }
                    } label: {
                        Image(systemName: isChromeHidden ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.toggleChrome"))

                    Button {
                        toggleAlbanian()
                    } label: {
                        LanguageToggleIcon(label: "AL", isActive: showAlbanianText)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.toggleAlbanian"))

                    Button {
                        toggleArabic()
                    } label: {
                        LanguageToggleIcon(label: "AR", isActive: showArabicText)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.toggleArabic"))
                    Button {
                        viewModel.decreaseFont()
                    } label: {
                        FontSizeButtonLabel(action: .decrease)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.font.decrease"))
                    Button {
                        viewModel.increaseFont()
                    } label: {
                        FontSizeButtonLabel(action: .increase)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.font.increase"))
                    Menu {
                        Button(LocalizedStringKey("reader.lineSpacing.decrease")) { viewModel.decreaseLineSpacing() }
                        Button(LocalizedStringKey("reader.lineSpacing.increase")) { viewModel.increaseLineSpacing() }
                    } label: {
                        Image(systemName: "text.line.first.and.arrowtriangle.forward")
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.lineSpacing"))
                    Button {
                        openNotesTab()
                    } label: {
                        Image(systemName: "note.text")
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                    .accessibilityLabel(LocalizedStringKey("reader.notesButton"))
                }
            }
            .tint(Color.kuraniAccentLight)
            .toolbar(isChromeHidden ? .hidden : .visible, for: .navigationBar)
            .toolbar(isChromeHidden ? .hidden : .visible, for: .tabBar)
            .onAppear {
                isChromeHidden = false
                if let startingAyah, viewModel.ayahs.contains(where: { $0.number == startingAyah }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(startingAyah, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(KuraniTheme.background.ignoresSafeArea())
        .statusBarHidden(isChromeHidden)
        .sheet(isPresented: $viewModel.isNoteEditorPresented) {
            if let ayah = viewModel.selectedAyah {
                NoteEditorView(
                    ayah: ayah,
                    draft: $viewModel.noteDraft,
                    isSaving: viewModel.isSavingNote,
                    onCancel: { viewModel.isNoteEditorPresented = false },
                    onSave: {
                        Task { await viewModel.saveNote() }
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(item: $selectedDictionaryEntry) { entry in
            ArabicDictionaryDetailView(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(LocalizedStringKey("action.edit"), isPresented: $showingActions, presenting: selectedAyahForActions) { ayah in
            Button(LocalizedStringKey("action.copy")) { copyAyah(ayah) }
            Button(LocalizedStringKey("action.share")) { shareAyah(ayah) }
            Button(LocalizedStringKey("reader.addToNotes")) { openNoteEditor(for: ayah) }
            Button("PYET CHATGPT") { askChatGPT(about: ayah) }
            Button(LocalizedStringKey("action.cancel"), role: .cancel) {}
        }
        .overlay(alignment: .top) {
            ZStack(alignment: .top) {
                if isChromeHidden {
                    Color.clear
                        .frame(height: fullscreenTapZoneHeightTop)
                        .contentShape(Rectangle())
                        .onTapGesture { revealFullscreenChrome() }
                }

                VStack(spacing: 12) {
                    if showToast, let toastMessage = viewModel.toast {
                        ToastView(message: toastMessage)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if isChromeHidden, fullscreenControlsVisible {
                        HStack(spacing: 24) {
                            Button {
                                isChromeHidden = false
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .accessibilityLabel(LocalizedStringKey("action.back"))
                            .buttonStyle(.plain)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isChromeHidden = false
                                }
                            } label: {
                                Image(systemName: "arrow.down.right.and.arrow.up.left")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .accessibilityLabel(LocalizedStringKey("reader.toggleChrome"))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(Color.kuraniAccentLight)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 16)
            }
        }
        .overlay(alignment: .bottom) {
            ZStack(alignment: .bottom) {
                if isChromeHidden {
                    Color.clear
                        .frame(height: fullscreenTapZoneHeightBottom)
                        .contentShape(Rectangle())
                        .onTapGesture { revealFullscreenChrome() }
                }

                if viewModel.totalAyahs > 0, !isChromeHidden || fullscreenControlsVisible {
                    ReaderProgressBar(
                        progress: viewModel.readingProgress,
                        percentage: viewModel.progressPercentageString,
                        detail: viewModel.progressDescription,
                        isChromeHidden: isChromeHidden
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .onChange(of: viewModel.toast) { _, newValue in
            guard newValue != nil else { return }
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showToast = false }
                viewModel.toast = nil
            }
        }
        .onChange(of: isChromeHidden) { _, _ in
            fullscreenHideWorkItem?.cancel()
            fullscreenHideWorkItem = nil
            fullscreenControlsVisible = false
        }
    }

    private func openNoteEditor(for ayah: Ayah) {
        viewModel.openNoteEditor(for: ayah)
    }

    private func copyAyah(_ ayah: Ayah) {
        UIPasteboard.general.string = formattedText(for: ayah)
        viewModel.toast = LocalizedStringKey("reader.copy.confirmation")
    }

    private func shareAyah(_ ayah: Ayah) {
        shareText = formattedText(for: ayah)
        showingShareSheet = true
    }

    private func askChatGPT(about ayah: Ayah) {
        let prompt = "Më trego më shumë rreth sures \(viewModel.surahTitle), ajeti \(ayah.number). Teksti: \(ayah.text)"
        guard let encodedPrompt = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let url = URL(string: "https://chat.openai.com/?q=\(encodedPrompt)") else { return }
        openURL(url)
    }

    private func toggleAlbanian() {
        if showAlbanianText {
            if !showArabicText {
                showArabicText = true
            }
            showAlbanianText = false
        } else {
            showAlbanianText = true
        }
    }

    private func toggleArabic() {
        if showArabicText {
            if !showAlbanianText {
                showAlbanianText = true
            }
            showArabicText = false
        } else {
            showArabicText = true
        }
    }

    private func formattedText(for ayah: Ayah) -> String {
        "\(viewModel.surahTitle) \(ayah.number): \(ayah.text)"
    }

    private func handleDictionarySelection(_ word: String) {
        guard pendingDictionaryWord != word else { return }
        pendingDictionaryWord = word

        if let entry = ArabicDictionary.shared.lookup(word: word) {
            selectedDictionaryEntry = entry
        } else {
            viewModel.toast = LocalizedStringKey("dictionary.notFound")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pendingDictionaryWord = nil
        }
    }

    private func revealFullscreenChrome() {
        guard isChromeHidden else { return }
        fullscreenHideWorkItem?.cancel()
        withAnimation { fullscreenControlsVisible = true }

        let workItem = DispatchWorkItem {
            guard isChromeHidden else { return }
            withAnimation { fullscreenControlsVisible = false }
            fullscreenHideWorkItem = nil
        }
        fullscreenHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
}

private struct NoteMarker: View {
    var body: some View {
        Image(systemName: "note.text")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.kuraniDarkBackground)
            .padding(4)
            .background(Circle().fill(Color.kuraniAccentLight))
            .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
            .accessibilityHidden(true)
    }
}

private struct LanguageToggleIcon: View {
    let label: String
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.kuraniAccentLight : .clear)
                .overlay(
                    Circle()
                        .stroke(Color.kuraniAccentLight, lineWidth: 1.4)
                )

            Text(label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? Color.kuraniDarkBackground : Color.kuraniAccentLight)
        }
        .frame(width: 30, height: 30)
    }
}

private struct ReaderProgressTitle: View {
    let title: String
    let percentage: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)

            ProgressBadge(percentage: percentage)
        }
    }
}

private struct ReaderProgressBar: View {
    let progress: Double
    let percentage: String
    let detail: String
    let isChromeHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(percentage)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.kuraniTextPrimary)
                Spacer()
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.kuraniTextSecondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.kuraniAccentLight)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.kuraniPrimarySurface.opacity(isChromeHidden ? 0.72 : 0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.6)
                )
        )
    }
}

