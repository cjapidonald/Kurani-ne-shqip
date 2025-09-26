import Foundation

struct ArabicDictionaryEntry: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let transliteration: String
    let meanings: [String]
    let notes: String?
}
