import Foundation

struct Note: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let surah: Int
    let ayah: Int
    var text: String
    var updatedAt: Date

    init(id: UUID = UUID(), userId: UUID, surah: Int, ayah: Int, text: String, updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.surah = surah
        self.ayah = ayah
        self.text = text
        self.updatedAt = updatedAt
    }
}

extension Array where Element == Note {
    func groupedBySurah() -> [Int: [Note]] {
        Dictionary(grouping: self, by: { $0.surah })
    }
}
