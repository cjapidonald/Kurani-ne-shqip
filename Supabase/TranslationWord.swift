import Foundation

struct TranslationWord: Codable, Hashable, Identifiable {
    let surah: Int
    let ayah: Int
    let position: Int
    let arabicWord: String
    let albanianWord: String

    var id: String { "\(surah)-\(ayah)-\(position)" }

    enum CodingKeys: String, CodingKey {
        case surah
        case ayah
        case position
        case arabicWord = "arabic_word"
        case albanianWord = "albanian_word"
    }
}
