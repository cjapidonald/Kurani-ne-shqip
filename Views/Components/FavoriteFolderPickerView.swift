import SwiftUI

struct FavoriteFolderPickerView: View {
    enum Result {
        case inserted(folderName: String, isNewFolder: Bool)
        case updated(folderName: String)
        case failed
        case cancelled
    }

    let ayah: Ayah
    let surahNumber: Int
    let surahTitle: String
    let noteText: String?
    let onComplete: (Result) -> Void

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    @State private var newFolderName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    private var sanitizedNote: String? {
        let trimmed = noteText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(LocalizedStringKey("favorites.folderPicker.ayah"))) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(surahTitle) • \(ayah.number)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.kuraniTextSecondary)
                        Text(ayah.text)
                            .font(KuraniFont.forTextStyle(.body))
                            .foregroundColor(.kuraniTextPrimary)
                    }
                    if let sanitizedNote {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey("favorites.folderPicker.noteLabel"))
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(.kuraniTextSecondary)
                            Text(sanitizedNote)
                                .font(KuraniFont.forTextStyle(.callout))
                                .foregroundColor(.kuraniAccentLight)
                                .lineLimit(4)
                        }
                        .padding(.top, 6)
                    } else {
                        Text(LocalizedStringKey("favorites.folderPicker.noNote"))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.kuraniTextSecondary)
                            .padding(.top, 6)
                    }
                }

                Section(header: Text(LocalizedStringKey("favorites.folderPicker.existing"))) {
                    if favoritesStore.folders.isEmpty {
                        Text(LocalizedStringKey("favorites.folderPicker.noFolders"))
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.kuraniTextSecondary)
                    } else {
                        ForEach(favoritesStore.folders) { folder in
                            Button {
                                addToExisting(folder)
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(.kuraniAccentLight)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(folder.name)
                                            .foregroundColor(.kuraniTextPrimary)
                                        Text(folderDetail(for: folder))
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.kuraniTextSecondary)
                                    }
                                    Spacer()
                                    if folder.entries.contains(where: { $0.surah == surahNumber && $0.ayah == ayah.number }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.kuraniAccentLight)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text(LocalizedStringKey("favorites.folderPicker.new"))) {
                    TextField(LocalizedStringKey("favorites.folderPicker.placeholder"), text: $newFolderName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .focused($isNameFieldFocused)

                    Button(LocalizedStringKey("favorites.folderPicker.create")) {
                        createFolder()
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(LocalizedStringKey("favorites.folderPicker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("action.cancel")) {
                        onComplete(.cancelled)
                        dismiss()
                    }
                }
            }
        }
    }

    private func folderDetail(for folder: FavoriteFolder) -> String {
        let count = folder.entries.count
        if count == 1 {
            return NSLocalizedString("favorites.folderPicker.count.single", comment: "single ayah")
        }
        return String(format: NSLocalizedString("favorites.folderPicker.count", comment: "ayah count"), count)
    }

    private func addToExisting(_ folder: FavoriteFolder) {
        let result = favoritesStore.addAyahToFolder(surah: surahNumber, ayah: ayah.number, note: sanitizedNote, folderId: folder.id)
        switch result {
        case .inserted:
            onComplete(.inserted(folderName: folder.name, isNewFolder: false))
        case .updated:
            onComplete(.updated(folderName: folder.name))
        case .failed:
            onComplete(.failed)
        }
        dismiss()
    }

    private func createFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let entry = FavoriteFolder.Entry(surah: surahNumber, ayah: ayah.number, note: sanitizedNote, addedAt: Date())
        let folder = favoritesStore.createFolder(named: trimmed, inserting: entry)
        newFolderName = ""
        onComplete(.inserted(folderName: folder.name, isNewFolder: true))
        dismiss()
    }
}
