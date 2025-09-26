import Foundation
import Supabase

enum NotesError: LocalizedError {
    case unauthenticated

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return NSLocalizedString("signin.required", comment: "Authentication required")
        }
    }
}

@MainActor
final class NotesStore: ObservableObject {
    @Published private(set) var notes: [Note] = []
    @Published private(set) var isLoading = false

    private let client: SupabaseClient
    private var currentUserId: UUID?
    private let localStorage = LocalNotesStorage()
    private let localUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    init(client: SupabaseClient) {
        self.client = client
        notes = localStorage.load()
    }

    func observeAuthChanges(authManager: AuthManager) async {
        for await userId in authManager.$userId.values {
            currentUserId = userId
            if userId == nil {
                notes = localStorage.load()
                isLoading = false
            } else {
                await fetchAll()
            }
        }
    }

    func fetchAll() async {
        guard let userId = currentUserId else {
            isLoading = false
            notes = localStorage.load()
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let response: PostgrestResponse<[NoteDTO]> = try await client.from("notes")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("surah", ascending: true)
                .order("ayah", ascending: true)
                .execute()
            self.notes = response.value.compactMap { $0.note }
        } catch {
            print("Failed to fetch notes", error)
        }
    }

    func fetch(for surah: Int) -> [Note] {
        notes.filter { $0.surah == surah }
    }

    func note(for surah: Int, ayah: Int) -> Note? {
        notes.first { $0.surah == surah && $0.ayah == ayah }
    }

    func upsertNote(surah: Int, ayah: Int, text: String) async throws {
        if let userId = currentUserId {
            let payload = NoteInsert(user_id: userId.uuidString, surah: surah, ayah: ayah, text: text)
            let response: PostgrestResponse<[NoteDTO]> = try await client.from("notes")
                .upsert([payload], onConflict: "user_id,surah,ayah")
                .select()
                .execute()
            if let dto = response.value.first?.note {
                if let index = notes.firstIndex(where: { $0.surah == dto.surah && $0.ayah == dto.ayah }) {
                    notes[index] = dto
                } else {
                    notes.append(dto)
                    notes.sort { lhs, rhs in
                        if lhs.surah == rhs.surah {
                            return lhs.ayah < rhs.ayah
                        }
                        return lhs.surah < rhs.surah
                    }
                }
            }
            return
        }

        let now = Date()
        if let index = notes.firstIndex(where: { $0.surah == surah && $0.ayah == ayah }) {
            var updatedNote = notes[index]
            updatedNote.text = text
            updatedNote.updatedAt = now
            notes[index] = updatedNote
        } else {
            let note = Note(userId: localUserId, surah: surah, ayah: ayah, text: text, updatedAt: now)
            notes.append(note)
        }

        notes.sort { lhs, rhs in
            if lhs.surah == rhs.surah {
                return lhs.ayah < rhs.ayah
            }
            return lhs.surah < rhs.surah
        }

        localStorage.save(notes)
    }
}

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [FavoriteAyah] = []
    @Published private(set) var folders: [FavoriteFolder] = []

    private let storage = LocalFavoritesStorage()
    private let folderStorage = LocalFavoriteFoldersStorage()

    init() {
        favorites = storage.load().sorted { $0.addedAt > $1.addedAt }
        folders = folderStorage.load()
    }

    func toggleFavorite(surah: Int, ayah: Int) {
        if isFavorite(surah: surah, ayah: ayah) {
            removeFavorite(surah: surah, ayah: ayah)
        } else {
            addFavorite(surah: surah, ayah: ayah)
        }
    }

    func addFavorite(surah: Int, ayah: Int) {
        guard !isFavorite(surah: surah, ayah: ayah) else { return }
        let favorite = FavoriteAyah(surah: surah, ayah: ayah, addedAt: Date())
        favorites.insert(favorite, at: 0)
        saveFavorites()
    }

    func removeFavorite(surah: Int, ayah: Int) {
        favorites.removeAll { $0.surah == surah && $0.ayah == ayah }
        saveFavorites()
    }

    func isFavorite(surah: Int, ayah: Int) -> Bool {
        favorites.contains { $0.surah == surah && $0.ayah == ayah }
    }

    @discardableResult
    func createFolder(named name: String, inserting entry: FavoriteFolder.Entry? = nil) -> FavoriteFolder {
        var folder = FavoriteFolder(name: name, entries: [])
        if let entry {
            folder.entries = [entry]
        }
        folders.insert(folder, at: 0)
        saveFolders()
        return folder
    }

    @discardableResult
    func addAyahToFolder(surah: Int, ayah: Int, note: String?, folderId: FavoriteFolder.ID) -> FavoriteFolderInsertionResult {
        guard let index = folders.firstIndex(where: { $0.id == folderId }) else { return .failed }
        let sanitizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = sanitizedNote?.isEmpty == false ? sanitizedNote : nil
        let now = Date()

        if let entryIndex = folders[index].entries.firstIndex(where: { $0.surah == surah && $0.ayah == ayah }) {
            folders[index].entries[entryIndex].note = finalNote
            folders[index].entries[entryIndex].addedAt = now
            folders[index].entries.sort { $0.addedAt > $1.addedAt }
            saveFolders()
            return .updated
        }

        let entry = FavoriteFolder.Entry(surah: surah, ayah: ayah, note: finalNote, addedAt: now)
        folders[index].entries.insert(entry, at: 0)
        saveFolders()
        return .inserted
    }

    func removeEntry(_ entry: FavoriteFolder.Entry, from folderId: FavoriteFolder.ID) {
        guard let index = folders.firstIndex(where: { $0.id == folderId }) else { return }
        folders[index].entries.removeAll { $0.id == entry.id }
        saveFolders()
    }

    func deleteFolder(_ folderId: FavoriteFolder.ID) {
        folders.removeAll { $0.id == folderId }
        saveFolders()
    }

    func updateNoteSnapshot(for surah: Int, ayah: Int, note: String?) {
        let sanitizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = sanitizedNote?.isEmpty == false ? sanitizedNote : nil
        var didChange = false
        for folderIndex in folders.indices {
            for entryIndex in folders[folderIndex].entries.indices {
                guard folders[folderIndex].entries[entryIndex].surah == surah,
                      folders[folderIndex].entries[entryIndex].ayah == ayah else { continue }
                folders[folderIndex].entries[entryIndex].note = finalNote
                didChange = true
            }
        }
        if didChange {
            saveFolders()
        }
    }

    private func saveFavorites() {
        favorites.sort { $0.addedAt > $1.addedAt }
        storage.save(favorites)
    }

    private func saveFolders() {
        var updated = folders.map { folder -> FavoriteFolder in
            var mutable = folder
            mutable.entries.sort { $0.addedAt > $1.addedAt }
            return mutable
        }
        updated.sort { $0.createdAt > $1.createdAt }
        folders = updated
        folderStorage.save(updated)
    }
}

enum FavoriteFolderInsertionResult {
    case inserted
    case updated
    case failed
}

private struct LocalNotesStorage {
    private let fileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("local-notes.json")
    }()

    func load() -> [Note] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("Failed to decode local notes", error)
            return []
        }
    }

    func save(_ notes: [Note]) {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save local notes", error)
        }
    }
}

private struct LocalFavoritesStorage {
    private let fileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("favorites.json")
    }()

    func load() -> [FavoriteAyah] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            let favorites = try JSONDecoder().decode([FavoriteAyah].self, from: data)
            return favorites.sorted { $0.addedAt > $1.addedAt }
        } catch {
            print("Failed to decode favorites", error)
            return []
        }
    }

    func save(_ favorites: [FavoriteAyah]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save favorites", error)
        }
    }
}

private struct LocalFavoriteFoldersStorage {
    private let fileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("favorite-folders.json")
    }()

    func load() -> [FavoriteFolder] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            let folders = try JSONDecoder().decode([FavoriteFolder].self, from: data)
            return folders.map { folder in
                var mutable = folder
                mutable.entries.sort { $0.addedAt > $1.addedAt }
                return mutable
            }.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("Failed to decode favorite folders", error)
            return []
        }
    }

    func save(_ folders: [FavoriteFolder]) {
        do {
            let data = try JSONEncoder().encode(folders)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save favorite folders", error)
        }
    }
}

private struct NoteInsert: Encodable {
    let user_id: String
    let surah: Int
    let ayah: Int
    let text: String
}

private struct NoteDTO: Codable {
    let id: UUID?
    let user_id: String
    let surah: Int
    let ayah: Int
    let text: String
    let updated_at: Date

    var note: Note? {
        guard let id = id, let userId = UUID(uuidString: user_id) else { return nil }
        return Note(id: id, userId: userId, surah: surah, ayah: ayah, text: text, updatedAt: updated_at)
    }
}
