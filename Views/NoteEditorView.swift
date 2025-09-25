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
            VStack(alignment: .leading, spacing: 16) {
                Text(String(format: NSLocalizedString("reader.title.compact", comment: "title"), ayah.number, ayah.text))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.textSecondary)

                TextEditor(text: $draft)
                    .focused($isFocused)
                    .frame(minHeight: 160)
                    .padding(8)
                    .background(Color.primarySurface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.textPrimary)
            }
            .padding()
            .background(Color.darkBackground.ignoresSafeArea())
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}
