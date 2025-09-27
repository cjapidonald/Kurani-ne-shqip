import Foundation
import Supabase

struct ArabicTextFetchResult {
    let arabicBySurah: [Int: [Int: String]]
    let fetchedWords: [TranslationWord]

    static let empty = ArabicTextFetchResult(arabicBySurah: [:], fetchedWords: [])
}

protocol TranslationService {
    func fetchSurahMetadata() async throws -> [Surah]
    func fetchArabicTextBySurah(surah: Int?, ayahRange: ClosedRange<Int>?) async throws -> ArabicTextFetchResult
}

extension TranslationService {
    func fetchArabicTextBySurah() async throws -> ArabicTextFetchResult {
        try await fetchArabicTextBySurah(surah: nil, ayahRange: nil)
    }
}

final class SupabaseTranslationService: TranslationService {
    private let clientProvider: () throws -> SupabaseClient
    private var cachedSurahs: [Surah]?
    private var cachedArabicTextBySurah: [Int: [Int: String]] = [:]
    private var fullyLoadedSurahs: Set<Int> = []
    private var hasLoadedAllArabicText = false

    init(clientProvider: @escaping () throws -> SupabaseClient = SupabaseClientProvider.client) {
        self.clientProvider = clientProvider
    }

    convenience init(client: SupabaseClient) {
        self.init(clientProvider: { client })
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

        let client = try clientProvider()
        let response: PostgrestResponse<[SurahMetadataRow]> = try await client
            .from("surah_metadata")
            .select()
            .order("number", ascending: true)
            .execute()

        let surahs = response.value.map { Surah(number: $0.number, name: $0.name, ayahCount: $0.ayahCount) }
        cachedSurahs = surahs
        return surahs
    }

    func fetchArabicTextBySurah(surah: Int? = nil, ayahRange: ClosedRange<Int>? = nil) async throws -> ArabicTextFetchResult {
        guard needsFetch(for: surah, ayahRange: ayahRange) else {
            return ArabicTextFetchResult(arabicBySurah: cachedArabicTextBySurah, fetchedWords: [])
        }

        let words = try await loadArabicData(surah: surah, ayahRange: ayahRange)
        if words.isEmpty {
            markSurahAsLoadedIfNeeded(surah: surah, ayahRange: ayahRange)
            return ArabicTextFetchResult(arabicBySurah: cachedArabicTextBySurah, fetchedWords: [])
        }

        let aggregates = Self.buildArabicAggregates(from: words)
        mergeArabicAggregates(aggregates)
        markSurahAsLoadedIfNeeded(surah: surah, ayahRange: ayahRange)

        return ArabicTextFetchResult(arabicBySurah: cachedArabicTextBySurah, fetchedWords: words)
    }
}

private extension SupabaseTranslationService {
    func needsFetch(for surah: Int?, ayahRange: ClosedRange<Int>?) -> Bool {
        if hasLoadedAllArabicText { return false }

        guard let surah else { return true }

        if let ayahRange {
            let cachedAyahs = cachedArabicTextBySurah[surah] ?? [:]
            for ayah in ayahRange {
                if cachedAyahs[ayah] == nil {
                    return true
                }
            }
            return false
        }

        return !fullyLoadedSurahs.contains(surah)
    }

    func loadArabicData(surah: Int?, ayahRange: ClosedRange<Int>?) async throws -> [TranslationWord] {
        let client = try clientProvider()
        var query = client
            .from("translation")
            .select()

        if let surah {
            query = query.eq("surah", value: surah)
        }

        if let ayahRange {
            query = query
                .gte("ayah", value: ayahRange.lowerBound)
                .lte("ayah", value: ayahRange.upperBound)
        }

        let response: PostgrestResponse<[TranslationWord]> = try await query
            .order("surah", ascending: true)
            .order("ayah", ascending: true)
            .order("position", ascending: true)
            .execute()

        return response.value
    }

    func mergeArabicAggregates(_ aggregates: [Int: [Int: String]]) {
        guard !aggregates.isEmpty else { return }

        for (surah, ayahMap) in aggregates {
            var existing = cachedArabicTextBySurah[surah] ?? [:]
            for (ayah, text) in ayahMap {
                existing[ayah] = text
            }
            cachedArabicTextBySurah[surah] = existing
        }
    }

    func markSurahAsLoadedIfNeeded(surah: Int?, ayahRange: ClosedRange<Int>?) {
        if surah == nil && ayahRange == nil {
            hasLoadedAllArabicText = true
            fullyLoadedSurahs = Set(cachedArabicTextBySurah.keys)
            return
        }

        guard let surah, ayahRange == nil else { return }
        fullyLoadedSurahs.insert(surah)
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
