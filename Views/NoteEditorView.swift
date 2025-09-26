import SwiftUI

struct NoteEditorView: View {
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
                    .font(.system(.subheadline, design: .rounded))
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
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                            .shadow(color: Color.black.opacity(0.32), radius: 20, y: 14)
                    )
                    .foregroundColor(.kuraniTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(KuraniTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle(draft.isEmpty ? LocalizedStringKey("reader.note.add") : LocalizedStringKey("reader.note.edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onCancel) {
                        Text(LocalizedStringKey("action.cancel"))
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onSave) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedStringKey("action.ok"))
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
