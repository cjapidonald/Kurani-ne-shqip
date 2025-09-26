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
