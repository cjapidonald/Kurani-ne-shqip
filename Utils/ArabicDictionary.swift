import Foundation

final class ArabicDictionary {
    static let shared = ArabicDictionary()

    private var entriesByNormalizedWord: [String: ArabicDictionaryEntry] = [:]
    private let normalizationSet: CharacterSet

    private init() {
        var combining = CharacterSet()
        for value in 0x064B...0x065F {
            if let scalar = UnicodeScalar(value) {
                combining.insert(scalar)
            }
        }
        if let daggerAlif = UnicodeScalar(0x0670) {
            combining.insert(daggerAlif)
        }
        for value in 0x06D6...0x06ED {
            if let scalar = UnicodeScalar(value) {
                combining.insert(scalar)
            }
        }
        normalizationSet = combining
        loadEntries()
    }

    private func loadEntries() {
        guard let url = Bundle.main.url(forResource: "ArabicDictionary", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let entries = try decoder.decode([ArabicDictionaryEntry].self, from: data)
            entriesByNormalizedWord = Dictionary(uniqueKeysWithValues: entries.map { entry in
                let normalized = normalize(entry.word)
                return (normalized, entry)
            })
        } catch {
            print("Failed to load Arabic dictionary: \(error)")
        }
    }

    func lookup(word: String) -> ArabicDictionaryEntry? {
        let normalized = normalize(word)
        if let entry = entriesByNormalizedWord[normalized] {
            return entry
        }

        // Try trimming common punctuation marks
        let trimmed = word.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        if trimmed != word {
            let trimmedNormalized = normalize(trimmed)
            return entriesByNormalizedWord[trimmedNormalized]
        }

        return nil
    }

    private func normalize(_ word: String) -> String {
        let noTashkeel = word.unicodeScalars.filter { scalar in
            !normalizationSet.contains(scalar)
        }
        let normalized = String(String.UnicodeScalarView(noTashkeel))
            .replacingOccurrences(of: "ٱ", with: "ا")
            .replacingOccurrences(of: "آ", with: "ا")
            .replacingOccurrences(of: "إ", with: "ا")
            .replacingOccurrences(of: "أ", with: "ا")
        return normalized
    }
}
