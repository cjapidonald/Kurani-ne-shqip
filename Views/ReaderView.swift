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
                        AyahRowView(
                            ayah: ayah,
                            showAlbanianText: showAlbanianText,
                            showArabicText: showArabicText,
                            fontScale: viewModel.fontScale,
                            lineSpacingScale: viewModel.lineSpacingScale,
                            isFavorite: viewModel.isFavoriteAyah(ayah),
                            note: viewModel.note(for: ayah),
                            onOpenActions: {
                                selectedAyahForActions = ayah
                                showingActions = true
                            },
                            onToggleFavorite: {
                                viewModel.toggleFavoriteStatus(for: ayah)
                            },
                            onOpenNoteEditor: {
                                openNoteEditor(for: ayah)
                            },
                            onCopy: {
                                copyAyah(ayah)
                            },
                            onShare: {
                                shareAyah(ayah)
                            },
                            onAskChatGPT: {
                                askChatGPT(about: ayah)
                            },
                            onArabicSelection: handleDictionarySelection
                        )
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
                    ReaderProgressTitle(title: viewModel.surahTitle)
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
                BoundNoteEditorView(
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
            ArabicDictionaryDetailView(entry: entry) {
                askChatGPT(aboutWord: entry.word)
            }
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

                    if !isChromeHidden {
                        ReaderToolbarControls(
                            isChromeHidden: isChromeHidden,
                            showAlbanianText: showAlbanianText,
                            showArabicText: showArabicText,
                            onToggleChrome: toggleChrome,
                            onToggleAlbanian: toggleAlbanian,
                            onToggleArabic: toggleArabic,
                            onDecreaseFont: viewModel.decreaseFont,
                            onIncreaseFont: viewModel.increaseFont,
                            onOpenNotes: openNotesTab
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
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
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
        }
        .overlay(alignment: .bottom) {
            if isChromeHidden {
                Color.clear
                    .frame(height: fullscreenTapZoneHeightBottom)
                    .contentShape(Rectangle())
                    .onTapGesture { revealFullscreenChrome() }
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
        openChatGPT(with: prompt)
    }

    private func askChatGPT(aboutWord word: String) {
        let prompt = "Përshëndetje! Më trego më shumë për kuptimin e fjalës \"\(word)\" në arabisht."
        openChatGPT(with: prompt)
    }

    private func openChatGPT(with prompt: String) {
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

    private func toggleChrome() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isChromeHidden.toggle()
        }
    }

    private func formattedText(for ayah: Ayah) -> String {
        "\(viewModel.surahTitle) \(ayah.number): \(ayah.text)"
    }

    private func handleDictionarySelection(_ word: String) {
        guard pendingDictionaryWord != word else { return }
        pendingDictionaryWord = word
        viewModel.toast = LocalizedStringKey("dictionary.loading")

        Task {
            do {
                if let entry = try await ArabicDictionary.shared.lookup(word: word) {
                    await MainActor.run {
                        selectedDictionaryEntry = entry
                        viewModel.toast = nil
                    }
                } else {
                    await MainActor.run {
                        viewModel.toast = LocalizedStringKey("dictionary.notFound")
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.toast = LocalizedStringKey("dictionary.error")
                }
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                pendingDictionaryWord = nil
            }
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

private struct FontSizeButtonLabel: View {
    enum Action { case decrease, increase }
    let action: Action

    var body: some View {
        Image(systemName: action == .increase ? "textformat.size.larger" : "textformat.size.smaller")
            .foregroundStyle(Color.kuraniAccentLight)
    }
}

private struct ReaderToolbarControls: View {
    let isChromeHidden: Bool
    let showAlbanianText: Bool
    let showArabicText: Bool
    let onToggleChrome: () -> Void
    let onToggleAlbanian: () -> Void
    let onToggleArabic: () -> Void
    let onDecreaseFont: () -> Void
    let onIncreaseFont: () -> Void
    let onOpenNotes: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleChrome) {
                Image(systemName: isChromeHidden ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .foregroundStyle(Color.kuraniAccentLight)
            }
            .accessibilityLabel(LocalizedStringKey("reader.toggleChrome"))

            Button(action: onToggleAlbanian) {
                LanguageToggleIcon(label: "AL", isActive: showAlbanianText)
            }
            .accessibilityLabel(LocalizedStringKey("reader.toggleAlbanian"))

            Button(action: onToggleArabic) {
                LanguageToggleIcon(label: "AR", isActive: showArabicText)
            }
            .accessibilityLabel(LocalizedStringKey("reader.toggleArabic"))

            Button(action: onDecreaseFont) {
                FontSizeButtonLabel(action: .decrease)
            }
            .accessibilityLabel(LocalizedStringKey("reader.font.decrease"))

            Button(action: onIncreaseFont) {
                FontSizeButtonLabel(action: .increase)
            }
            .accessibilityLabel(LocalizedStringKey("reader.font.increase"))

            Button(action: onOpenNotes) {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.kuraniAccentLight)
            }
            .accessibilityLabel(LocalizedStringKey("reader.notesButton"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .buttonStyle(.plain)
    }
}

private struct ReaderProgressTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
    }
}

private struct AyahRowView: View {
    let ayah: Ayah
    let showAlbanianText: Bool
    let showArabicText: Bool
    let fontScale: Double
    let lineSpacingScale: Double
    let isFavorite: Bool
    let note: Note?
    let onOpenActions: () -> Void
    let onToggleFavorite: () -> Void
    let onOpenNoteEditor: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    let onAskChatGPT: () -> Void
    let onArabicSelection: (String) -> Void

    private static let noteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 12) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isFavorite ? Color.kuraniAccentBrand : Color.kuraniAccentLight.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite ? LocalizedStringKey("reader.favorite.remove") : LocalizedStringKey("reader.favorite.add"))

                    Button(action: onOpenActions) {
                        ZStack(alignment: .topTrailing) {
                            Pill(number: ayah.number)
                            if note != nil {
                                NoteMarker()
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(minWidth: 48)

                VStack(alignment: .leading, spacing: 6) {
                    if showAlbanianText {
                        Text(ayah.text)
                            .font(KuraniFont.size(18 * fontScale, relativeTo: .body))
                            .foregroundColor(.kuraniTextPrimary)
                            .lineSpacing(4 * lineSpacingScale)
                            .contextMenu {
                                Button(LocalizedStringKey("reader.addToNotes")) { onOpenNoteEditor() }
                                Button(LocalizedStringKey("action.copy")) { onCopy() }
                                Button(LocalizedStringKey("action.share")) { onShare() }
                                Button("PYET CHATGPT") { onAskChatGPT() }
                            }
                            .onTapGesture { onOpenNoteEditor() }
                    }

                    if showArabicText, let arabic = ayah.arabicText {
                        ArabicSelectableTextView(
                            text: arabic,
                            fontScale: fontScale,
                            lineSpacingScale: lineSpacingScale,
                            onSelection: onArabicSelection
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let note {
                let formattedDate = Self.noteFormatter.string(from: note.updatedAt)
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
    }
}
