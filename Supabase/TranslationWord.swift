import Foundation

struct TranslationWord: Codable, Hashable {
    let surah: Int
    let ayah: Int
    let position: Int
    let albanianWord: String

    enum CodingKeys: String, CodingKey {
        case surah
        case ayah
        case position
        case albanianWord = "albanian_word"
    }
}
