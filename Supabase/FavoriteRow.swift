import Foundation

struct FavoriteRow: Codable, Hashable {
    let id: UUID?
    let userId: UUID?
    let surah: Int?
    let ayah: Int?
    let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case surah
        case ayah
        case createdAt = "created_at"
    }
}
