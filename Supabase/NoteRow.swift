import Foundation

struct NoteRow: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let surah: Int
    let ayah: Int
    let albanianText: String
    let note: String
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case surah
        case ayah
        case albanianText = "albanian_text"
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
