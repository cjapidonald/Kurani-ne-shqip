import Foundation

struct FavoriteViewRow: Codable, Hashable {
    let surah: Int
    let ayah: Int
    let albanianText: String?

    enum CodingKeys: String, CodingKey {
        case surah
        case ayah
        case albanianText = "albanian_text"
    }
}
