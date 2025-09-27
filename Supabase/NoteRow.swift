import Foundation

struct NoteRow: Codable, Hashable {
    let surah: Int
    let ayah: Int
    let albanianText: String
    let note: String

    enum CodingKeys: String, CodingKey {
        case surah
        case ayah
        case albanianText = "albanian_text"
        case note
    }
}
