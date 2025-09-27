import SwiftUI

struct NoteEditorView: View {
    let surah: Int
    let ayah: Int
    @State private var albanianText: String
    @State private var userNote: String
    @State private var isLoadingAlbanianText = false
    @State private var isSaving = false
    @State private var showSignInPrompt = false
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var translationStore: TranslationStore

    private let quranService: QuranServicing

    init(surah: Int, ayah: Int, initialText: String, existingNote: String = "", quranService: QuranServicing = QuranService()) {
        self.surah = surah
        self.ayah = ayah
        self.quranService = quranService
        _albanianText = State(initialValue: initialText)
        _userNote = State(initialValue: existingNote)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    albanianSection
                    noteSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(KuraniTheme.background.ignoresSafeArea())
            .navigationTitle(LocalizedStringKey("reader.note.edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("action.cancel")) {
                        dismiss()
                    }
                    .font(KuraniFont.forTextStyle(.body))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { Task { await saveNote() } }) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("action.ok"))
                                .font(KuraniFont.forTextStyle(.body))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isAuthenticated || isSaving)
                }
            }
            .alert(isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Alert(
                    title: Text(LocalizedStringKey("Error")),
                    message: Text(errorMessage ?? ""),
                    dismissButton: .default(Text(LocalizedStringKey("action.ok")))
                )
            }
            .task { await loadAlbanianTextIfNeeded() }
            .onAppear { handleInitialAuthenticationState() }
            .onReceive(authManager.$userId) { userId in
                showSignInPrompt = (userId == nil)
            }
        }
        .sheet(isPresented: $showSignInPrompt) {
            SignInPromptView()
                .environmentObject(authManager)
        }
    }
}

private extension NoteEditorView {
    var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: NSLocalizedString("Surah %d", comment: "surah"), surah))
                .font(KuraniFont.forTextStyle(.subheadline))
                .foregroundColor(.kuraniTextSecondary)
            Text(String(format: NSLocalizedString("Ayah %d", comment: "ayah"), ayah))
                .font(KuraniFont.forTextStyle(.headline))
                .foregroundColor(.kuraniTextPrimary)
        }
    }

    @ViewBuilder
    var albanianSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Albanian Text"))
                .font(KuraniFont.forTextStyle(.callout))
                .foregroundColor(.kuraniTextSecondary)
            Group {
                if isLoadingAlbanianText {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.kuraniAccentLight)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text(albanianText)
                        .font(KuraniFont.forTextStyle(.body))
                        .foregroundColor(.kuraniTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(cardBackground)
        }
    }

    var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Personal Note"))
                .font(KuraniFont.forTextStyle(.callout))
                .foregroundColor(.kuraniTextSecondary)
            TextEditor(text: $userNote)
                .frame(minHeight: 160)
                .padding(.vertical, 18)
                .padding(.horizontal, 16)
                .background(cardBackground)
                .foregroundColor(.kuraniTextPrimary)
                .font(KuraniFont.forTextStyle(.body))
        }
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.kuraniPrimarySurface.opacity(0.58))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.8)
            )
    }

    var isAuthenticated: Bool {
        authManager.userId != nil
    }

    func handleInitialAuthenticationState() {
        if authManager.userId == nil {
            showSignInPrompt = true
        }
    }

    func loadAlbanianTextIfNeeded() async {
        guard albanianText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        await MainActor.run { isLoadingAlbanianText = true }
        await translationStore.loadInitialData()
        let text = translationStore.ayahs(for: surah).first(where: { $0.number == ayah })?.text ?? ""
        await MainActor.run {
            albanianText = text
            isLoadingAlbanianText = false
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = NSLocalizedString("noteEditor.localTextMissing", comment: "note editor error")
            }
        }
    }

    func saveNote() async {
        guard isAuthenticated else {
            showSignInPrompt = true
            return
        }

        await MainActor.run { isSaving = true }
        do {
            try await quranService.upsertMyNote(
                surah: surah,
                ayah: ayah,
                albanianText: albanianText,
                note: userNote
            )
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct BoundNoteEditorView: View {
    let ayah: Ayah
    @Binding var draft: String
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(String(format: NSLocalizedString("reader.title.compact", comment: "title"), ayah.number, ayah.text))
                    .font(KuraniFont.forTextStyle(.subheadline))
                    .foregroundColor(.kuraniTextSecondary)

                TextEditor(text: $draft)
                    .focused($isFocused)
                    .frame(minHeight: 220)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.kuraniPrimarySurface.opacity(0.58))
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(Color.kuraniPrimaryBrand.opacity(0.12), lineWidth: 0.8)
                            )
                            .shadow(color: Color.kuraniPrimaryBrand.opacity(0.32), radius: 20, y: 14)
                    )
                    .foregroundColor(.black)
                    .font(KuraniFont.forTextStyle(.body))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(KuraniTheme.background.ignoresSafeArea())
            .navigationTitle(draft.isEmpty ? LocalizedStringKey("reader.note.add") : LocalizedStringKey("reader.note.edit"))
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
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .tint(.kuraniAccentLight)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    let authManager = AuthManager.previewManager()
    let translationStore = TranslationStore.previewStore()
    NoteEditorView(
        surah: 1,
        ayah: 1,
        initialText: "",
        existingNote: "",
        quranService: MockQuranService()
    )
    .environmentObject(authManager)
    .environmentObject(translationStore)
}
#endif
