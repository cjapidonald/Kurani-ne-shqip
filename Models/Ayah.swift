import Foundation

struct Ayah: Identifiable, Codable {
    let number: Int
    let text: String
    var arabicText: String?

    var id: Int { number }
}

struct FavoriteAyah: Identifiable, Codable, Equatable {
    let surah: Int
    let ayah: Int
    let addedAt: Date

    var id: String { Self.id(for: surah, ayah: ayah) }

    static func id(for surah: Int, ayah: Int) -> String {
        "\(surah)-\(ayah)"
    }
}

struct FavoriteFolder: Identifiable, Codable, Equatable {
    struct Entry: Identifiable, Codable, Equatable {
        let id: UUID
        let surah: Int
        let ayah: Int
        var note: String?
        var addedAt: Date

        init(id: UUID = UUID(), surah: Int, ayah: Int, note: String?, addedAt: Date) {
            self.id = id
            self.surah = surah
            self.ayah = ayah
            self.note = note
            self.addedAt = addedAt
        }
    }

    let id: UUID
    var name: String
    let createdAt: Date
    var entries: [Entry]

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), entries: [Entry] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.entries = entries
    }
}
