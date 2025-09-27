import Foundation

struct FavoriteViewRow: Codable, Hashable, Identifiable {
    let id: UUID
    let userId: UUID
    let surah: Int
    let ayah: Int
    let createdAt: Date
    let arabicAyahText: String?
    let albanianAyahText: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case surah
        case ayah
        case createdAt = "created_at"
        case arabicAyahText = "arabic_ayah_text"
        case albanianAyahText = "albanian_ayah_text"
    }
}
