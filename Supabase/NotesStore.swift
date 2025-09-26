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

    private let storage = LocalFavoritesStorage()

    init() {
        favorites = storage.load().sorted { $0.addedAt > $1.addedAt }
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

    private func saveFavorites() {
        favorites.sort { $0.addedAt > $1.addedAt }
        storage.save(favorites)
    }
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
