import Foundation
import Supabase

protocol TranslationService {
    func fetchSurahMetadata() async throws -> [Surah]
    func fetchArabicTextBySurah() async throws -> [Int: [Int: String]]
}

final class SupabaseTranslationService: TranslationService {
    private let client: SupabaseClient
    private var cachedSurahs: [Surah]?
    private var cachedArabicTextBySurah: [Int: [Int: String]]?

    init(client: SupabaseClient = SupabaseClientProvider.client) {
        self.client = client
    }

    func fetchSurahMetadata() async throws -> [Surah] {
        if let cachedSurahs {
            return cachedSurahs
        }

        struct SurahMetadataRow: Decodable {
            let number: Int
            let name: String
            let ayahCount: Int

            private enum CodingKeys: String, CodingKey {
                case number
                case name
                case ayahCount = "ayah_count"
            }
        }

        let response: PostgrestResponse<[SurahMetadataRow]> = try await client
            .from("surah_metadata")
            .select()
            .order("number", ascending: true)
            .execute()

        let surahs = response.value.map { Surah(number: $0.number, name: $0.name, ayahCount: $0.ayahCount) }
        cachedSurahs = surahs
        return surahs
    }

    func fetchArabicTextBySurah() async throws -> [Int: [Int: String]] {
        if let cachedArabicTextBySurah {
            return cachedArabicTextBySurah
        }

        try await loadArabicDataIfNeeded()
        return cachedArabicTextBySurah ?? [:]
    }
}

private extension SupabaseTranslationService {
    func loadArabicDataIfNeeded() async throws {
        guard cachedArabicTextBySurah == nil else { return }

        let response: PostgrestResponse<[TranslationWord]> = try await client
            .from("translation")
            .select()
            .order("surah", ascending: true)
            .order("ayah", ascending: true)
            .order("position", ascending: true)
            .execute()

        let words = response.value
        cachedArabicTextBySurah = Self.buildArabicAggregates(from: words)
    }

    static func buildArabicAggregates(from words: [TranslationWord]) -> [Int: [Int: String]] {
        guard !words.isEmpty else { return [:] }

        let groupedBySurah = Dictionary(grouping: words, by: { $0.surah })
        var arabicResult: [Int: [Int: String]] = [:]

        for (surah, surahWords) in groupedBySurah {
            let groupedByAyah = Dictionary(grouping: surahWords, by: { $0.ayah })
            var arabicTexts: [Int: String] = [:]

            for ayahNumber in groupedByAyah.keys.sorted() {
                guard let ayahWords = groupedByAyah[ayahNumber]?.sorted(by: { $0.position < $1.position }) else { continue }
                let arabic = combine(words: ayahWords.map(\.arabicWord))
                arabicTexts[ayahNumber] = arabic
            }

            arabicResult[surah] = arabicTexts
        }

        return arabicResult
    }

    static func combine(words: [String]) -> String {
        guard !words.isEmpty else { return "" }
        var combined = words.joined(separator: " ")
        let punctuation = [",", ".", ";", ":", "?", "!", "،", "؛", "۔"]
        for symbol in punctuation {
            combined = combined.replacingOccurrences(of: " \(symbol)", with: symbol)
        }
        while combined.contains("  ") {
            combined = combined.replacingOccurrences(of: "  ", with: " ")
        }
        return combined.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
