import Foundation
import SwiftUI

struct TranslationFile: Codable {
    struct SurahTranslation: Codable {
        let number: Int
        let ayahs: [Ayah]
    }

    let surahs: [SurahTranslation]
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

    func loadInitialData() async {
        await loadSurahMeta()
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

    private func loadSampleTranslation() async {
        do {
            let translation = try FileIO.loadBundleJSON("sample_translation", as: TranslationFile.self)
            ayahsBySurah = translation.surahs.reduce(into: [:]) { result, entry in
                result[entry.number] = entry.ayahs.sorted { $0.number < $1.number }
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
            result[entry.number] = entry.ayahs.sorted { $0.number < $1.number }
        }
        isUsingSample = false
    }

    func ayahs(for surah: Int) -> [Ayah] {
        ayahsBySurah[surah] ?? []
    }

    func title(for surah: Int) -> String {
        surahs.first(where: { $0.number == surah })?.name ?? ""
    }
}
