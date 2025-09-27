import Foundation
import SwiftUI

@MainActor
final class TranslationStore: ObservableObject {
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var ayahsBySurah: [Int: [Ayah]] = [:]

    private let service: TranslationService
    private var arabicAyahsBySurah: [Int: [Int: String]] = [:]

    init(service: TranslationService = SupabaseTranslationService()) {
        self.service = service
    }

    func loadInitialData() async {
        await fetchSurahMetadata()
        await fetchArabicText()
        await fetchTranslations()
    }

    private func fetchSurahMetadata() async {
        do {
            let metadata = try await service.fetchSurahMetadata()
            surahs = metadata.sorted { $0.number < $1.number }
        } catch {
            print("Failed to load surah metadata", error)
        }
    }

    private func fetchArabicText() async {
        do {
            arabicAyahsBySurah = try await service.fetchArabicTextBySurah()
        } catch {
            print("Failed to load Arabic text", error)
            arabicAyahsBySurah = [:]
        }
    }

    private func fetchTranslations() async {
        do {
            let translations = try await service.fetchAyahsBySurah()
            var merged: [Int: [Ayah]] = [:]
            for (surah, ayahs) in translations {
                let sorted = ayahs.sorted { $0.number < $1.number }
                merged[surah] = applyArabicTextIfAvailable(to: sorted, surahNumber: surah)
            }
            ayahsBySurah = merged
        } catch {
            print("Failed to load translation", error)
            ayahsBySurah = [:]
        }
    }

    func ayahs(for surah: Int) -> [Ayah] {
        ayahsBySurah[surah] ?? []
    }

    func ayahCount(for surah: Int) -> Int {
        if let count = ayahsBySurah[surah]?.count, count > 0 {
            return count
        }
        return surahs.first(where: { $0.number == surah })?.ayahCount ?? 0
    }

    func title(for surah: Int) -> String {
        surahs.first(where: { $0.number == surah })?.name ?? ""
    }

    func randomAyahs(count: Int) -> [(surah: Int, ayah: Ayah)] {
        guard count > 0 else { return [] }
        let allAyahs: [(Int, Ayah)] = ayahsBySurah
            .sorted { $0.key < $1.key }
            .flatMap { (surah, ayahs) in ayahs.map { (surah, $0) } }
        guard !allAyahs.isEmpty else { return [] }

        let limit = min(count, allAyahs.count)
        var indices = Array(allAyahs.indices)
        indices.shuffle()

        return indices.prefix(limit).map { allAyahs[$0] }
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

#if DEBUG
extension TranslationStore {
    static func previewStore() -> TranslationStore {
        let service = PreviewTranslationService()
        let store = TranslationStore(service: service)
        Task { await store.loadInitialData() }
        return store
    }
}

private struct PreviewTranslationService: TranslationService {
    private let surahMetadata: [Surah]
    private let ayahs: [Int: [Ayah]]
    private let arabicBySurah: [Int: [Int: String]]

    init() {
        surahMetadata = [
            Surah(number: 1, name: "El-Fatiha", ayahCount: 7),
            Surah(number: 2, name: "El-Bekare", ayahCount: 286)
        ]

        let fatihaAyahs = [
            Ayah(number: 1, text: "Lavdërimi i takon Allahut, Zotit të botëve", arabicText: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَالَمِينَ"),
            Ayah(number: 2, text: "Mëshiruesi, Mëshirëbërësi", arabicText: "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"),
            Ayah(number: 3, text: "Sunduesi i Ditës së Gjykimit", arabicText: "مَالِكِ يَوْمِ ٱلدِّينِ")
        ]

        let ayatulKursi = [
            Ayah(
                number: 255,
                text: "Allahu – nuk ka zot tjetër përveç Tij, i Gjalli, Mbajtësi i gjithësisë",
                arabicText: "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ"
            )
        ]

        ayahs = [
            1: fatihaAyahs,
            2: ayatulKursi
        ]

        arabicBySurah = ayahs.mapValues { ayahs in
            Dictionary(uniqueKeysWithValues: ayahs.compactMap { ayah -> (Int, String)? in
                guard let arabic = ayah.arabicText else { return nil }
                return (ayah.number, arabic)
            })
        }
    }

    func fetchSurahMetadata() async throws -> [Surah] {
        surahMetadata
    }

    func fetchAyahsBySurah() async throws -> [Int: [Ayah]] {
        ayahs
    }

    func fetchArabicTextBySurah() async throws -> [Int: [Int: String]] {
        arabicBySurah
    }
}
#endif
