import Foundation

struct TranslationWord: Decodable, Identifiable {
    let surah: Int
    let ayah: Int
    let position: Int
    let arabicWord: String
    let albanianWord: String

    var id: String { "\(surah)-\(ayah)-\(position)" }

    private enum CodingKeys: String, CodingKey {
        case surah
        case ayah
        case position
        case arabicWord = "arabic_word"
        case albanianWord = "albanian_word"
    }
}

struct NoteRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let surah: Int
    let ayah: Int
    let albanianText: String
    let note: String
    let createdAt: Date
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
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

struct FavoriteRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let surah: Int
    let ayah: Int
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case surah
        case ayah
        case createdAt = "created_at"
    }
}

struct FavoriteViewRow: Decodable, Identifiable {
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
