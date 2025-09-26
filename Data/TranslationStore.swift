import Foundation
import SwiftUI

struct TranslationFile: Codable {
    struct SurahTranslation: Codable {
        let number: Int
        let ayahs: [Ayah]
    }

    let surahs: [SurahTranslation]
}

private struct ArabicTextFile: Codable {
    struct SurahText: Codable {
        let number: Int
        let ayahs: [AyahText]
    }

    struct AyahText: Codable {
        let number: Int
        let text: String
    }

    let surahs: [SurahText]
}

private struct MetaEntry: Codable {
    let number: Int
    let name: String
    let ayahs: Int
}

@MainActor
final class TranslationStore: ObservableObject {
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var ayahsBySurah: [Int: [Ayah]] = [:]
    @Published private(set) var isUsingSample: Bool = true

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private var arabicAyahsBySurah: [Int: [Int: String]] = [:]

    func loadInitialData() async {
        await loadSurahMeta()
        await loadArabicText()
        await loadSampleTranslation()
    }

    private func loadSurahMeta() async {
        do {
            let meta = try FileIO.loadBundleJSON("QuranMeta", as: [MetaEntry].self)
            let mapped: [Surah] = meta.map { Surah(number: $0.number, name: $0.name, ayahCount: $0.ayahs) }
            self.surahs = mapped.sorted { $0.number < $1.number }
        } catch {
            print("Failed to load surah metadata", error)
        }
    }

    private func loadArabicText() async {
        do {
            let file = try FileIO.loadBundleJSON("ArabicText", as: ArabicTextFile.self)
            arabicAyahsBySurah = file.surahs.reduce(into: [:]) { result, entry in
                result[entry.number] = entry.ayahs.reduce(into: [:]) { ayahMap, ayah in
                    ayahMap[ayah.number] = ayah.text
                }
            }
        } catch {
            print("Failed to load Arabic text", error)
        }
    }

    private func loadSampleTranslation() async {
        do {
            let translation = try FileIO.loadBundleJSON("sample_translation", as: TranslationFile.self)
            ayahsBySurah = translation.surahs.reduce(into: [:]) { result, entry in
                let sorted = entry.ayahs.sorted { $0.number < $1.number }
                result[entry.number] = applyArabicTextIfAvailable(to: sorted, surahNumber: entry.number)
            }
            isUsingSample = true
        } catch {
            print("Failed to load translation", error)
        }
    }

    func importTranslation(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let translation = try decoder.decode(TranslationFile.self, from: data)
        ayahsBySurah = translation.surahs.reduce(into: [:]) { result, entry in
            let sorted = entry.ayahs.sorted { $0.number < $1.number }
            result[entry.number] = applyArabicTextIfAvailable(to: sorted, surahNumber: entry.number)
        }
        isUsingSample = false
    }

    func ayahs(for surah: Int) -> [Ayah] {
        ayahsBySurah[surah] ?? []
    }

    func title(for surah: Int) -> String {
        surahs.first(where: { $0.number == surah })?.name ?? ""
    }

    private func applyArabicTextIfAvailable(to ayahs: [Ayah], surahNumber: Int) -> [Ayah] {
        guard let arabicMap = arabicAyahsBySurah[surahNumber] else { return ayahs }
        return ayahs.map { ayah in
            var enriched = ayah
            if enriched.arabicText == nil {
                enriched.arabicText = arabicMap[ayah.number]
            }
            return enriched
        }
    }
}
