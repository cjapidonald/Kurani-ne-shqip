import Foundation

actor ArabicDictionary {
    static let shared = ArabicDictionary()

    private var entriesByNormalizedWord: [String: ArabicDictionaryEntry] = [:]
    private let normalizationSet: CharacterSet
    private let service: QuranServicing
    private var didLoadEntries = false

    init(service: QuranServicing = QuranService()) {
        self.service = service

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
    }

    func lookup(word: String) async throws -> ArabicDictionaryEntry? {
        try await ensureEntriesLoaded()

        let normalized = normalize(word)
        if let entry = entriesByNormalizedWord[normalized] {
            return entry
        }

        let trimmed = word.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        guard trimmed != word else { return nil }

        return entriesByNormalizedWord[normalize(trimmed)]
    }

    private func ensureEntriesLoaded() async throws {
        guard !didLoadEntries else { return }

        do {
            let entries = try await service.loadArabicDictionary()
            entriesByNormalizedWord = Dictionary(uniqueKeysWithValues: entries.map { entry in
                let normalized = normalize(entry.word)
                return (normalized, entry)
            })
            didLoadEntries = true
        } catch {
            didLoadEntries = false
            entriesByNormalizedWord = [:]
            throw error
        }
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
