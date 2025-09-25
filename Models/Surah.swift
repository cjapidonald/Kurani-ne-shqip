import Foundation

struct Surah: Identifiable, Codable {
    let number: Int
    let name: String
    let ayahCount: Int

    var id: Int { number }
}
