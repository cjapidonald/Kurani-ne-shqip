import SwiftUI
import UIKit

struct ReaderView: View {
    @ObservedObject var viewModel: ReaderViewModel
    let startingAyah: Int?
    let openNotesTab: () -> Void

codex/update-app-theme-for-reading
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage(AppStorageKeys.showArabicText) private var showArabicText = false


main
    @State private var selectedAyahForActions: Ayah?
    @State private var showingActions = false
    @State private var shareText: String = ""
    @State private var showingShareSheet = false
    @State private var showToast = false

    private let noteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

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
                                    Pill(number: ayah.number)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(ayah.text)
                                        .font(.system(size: 18 * viewModel.fontScale, weight: .regular, design: .serif))
                                        .foregroundColor(.kuraniTextPrimary)
                                        .lineSpacing(4 * viewModel.lineSpacingScale)
                                        .contextMenu {
                                            Button(LocalizedStringKey("action.edit")) {
                                                openNoteEditor(for: ayah)
                                            }
                                            Button(LocalizedStringKey("action.copy")) {
                                                copyAyah(ayah)
                                            }
                                            Button(LocalizedStringKey("action.share")) {
                                                shareAyah(ayah)
                                            }
                                        }
                                        .onTapGesture {
                                            openNoteEditor(for: ayah)
                                        }

                                    if showArabicText, let arabic = ayah.arabicText {
                                        Text(arabic)
                                            .font(.system(size: 20 * viewModel.fontScale, weight: .regular))
                                            .foregroundColor(.kuraniTextPrimary)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                            .lineSpacing(4 * viewModel.lineSpacingScale)
                                    }
                                }
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
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(.kuraniTextSecondary)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color.kuraniPrimarySurface.opacity(0.68))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(Color.black.opacity(0.12), lineWidth: 0.6)
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
            .navigationTitle(Text(viewModel.surahTitle))
            .toolbarBackground(Color.kuraniDarkBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showArabicText.toggle()
                    } label: {
                        Image(systemName: showArabicText ? "book.closed.fill" : "book.closed")
                            .accessibilityLabel(LocalizedStringKey("reader.toggleArabic"))
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                    Button {
                        viewModel.decreaseFont()
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                            .accessibilityLabel(LocalizedStringKey("reader.font.decrease"))
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
                    Button {
                        viewModel.increaseFont()
                    } label: {
                        Image(systemName: "textformat.size.larger")
                            .accessibilityLabel(LocalizedStringKey("reader.font.increase"))
                            .foregroundStyle(Color.kuraniAccentLight)
                    }
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
            .onAppear {
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
        .confirmationDialog(LocalizedStringKey("action.edit"), isPresented: $showingActions, presenting: selectedAyahForActions) { ayah in
            Button(LocalizedStringKey("action.copy")) { copyAyah(ayah) }
            Button(LocalizedStringKey("action.share")) { shareAyah(ayah) }
            Button(LocalizedStringKey("action.edit")) { openNoteEditor(for: ayah) }
            Button(LocalizedStringKey("action.cancel"), role: .cancel) {}
        }
        .overlay(alignment: .top) {
            if showToast, let toastMessage = viewModel.toast {
                ToastView(message: toastMessage)
                    .padding(.top, 40)
                    .transition(.move(edge: .top).combined(with: .opacity))
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

    private func formattedText(for ayah: Ayah) -> String {
        "\(viewModel.surahTitle) \(ayah.number): \(ayah.text)"
    }
}

