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

    init(client: SupabaseClient) {
        self.client = client
    }

    func observeAuthChanges(authManager: AuthManager) async {
        for await userId in authManager.$userId.values {
            currentUserId = userId
            if userId == nil {
                notes = []
            } else {
                await fetchAll()
            }
        }
    }

    func fetchAll() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [NoteDTO] = try await client.database.from("notes")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("surah", ascending: true)
                .order("ayah", ascending: true)
                .execute()
                .decoded()
            self.notes = response.compactMap { $0.note }
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
        guard let userId = currentUserId else { throw NotesError.unauthenticated }
        let payload = NoteInsert(user_id: userId.uuidString, surah: surah, ayah: ayah, text: text)
        let result: [NoteDTO] = try await client.database.from("notes")
            .upsert(values: [payload], onConflict: "user_id,surah,ayah")
            .select()
            .execute()
            .decoded()
        if let dto = result.first?.note {
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
