import Foundation
import SwiftUI

@MainActor
final class TranslationStore: ObservableObject {
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var ayahsBySurah: [Int: [Ayah]] = [:]

    private let service: TranslationService
    private let albanianLoader: AlbanianQuranLoading
    private var arabicAyahsBySurah: [Int: [Int: String]] = [:]
    private var hasLoadedInitialData = false

    init(service: TranslationService = SupabaseTranslationService(), albanianLoader: AlbanianQuranLoading = AlbanianQuranLoader()) {
        self.service = service
        self.albanianLoader = albanianLoader
    }

    func loadInitialData() async {
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true

        loadAlbanianText()
        if !arabicAyahsBySurah.isEmpty {
            applyArabicTextToLocalDataset()
        }
        guard !surahs.isEmpty, !ayahsBySurah.isEmpty else { return }
        await fetchSurahMetadata()
        await fetchArabicText()

        if surahs.isEmpty || ayahsBySurah.isEmpty {
            hasLoadedInitialData = false
        }
    }

    private func loadAlbanianText() {
        do {
            let dataset = try albanianLoader.load()
            surahs = dataset.surahs.sorted { $0.number < $1.number }
            ayahsBySurah = dataset.ayahsBySurah.mapValues { $0.sorted { $0.number < $1.number } }
        } catch {
            print("Failed to load local Albanian Quran", error)
            surahs = []
            ayahsBySurah = [:]
            hasLoadedInitialData = false
        }
    }

    private func fetchSurahMetadata() async {
        do {
            let metadata = try await service.fetchSurahMetadata()
            guard !metadata.isEmpty else { return }
            let sorted = metadata.sorted { $0.number < $1.number }
            if sorted != surahs {
                surahs = sorted
            }
        } catch {
            print("Failed to load surah metadata", error)
        }
    }

    private func fetchArabicText() async {
        do {
            arabicAyahsBySurah = try await service.fetchArabicTextBySurah()
            applyArabicTextToLocalDataset()
        } catch {
            print("Failed to load Arabic text", error)
            arabicAyahsBySurah = [:]
            hasLoadedInitialData = false
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

    private func applyArabicTextToLocalDataset() {
        guard !arabicAyahsBySurah.isEmpty else { return }
        for (surahNumber, arabicMap) in arabicAyahsBySurah {
            guard var ayahs = ayahsBySurah[surahNumber], !ayahs.isEmpty else { continue }
            for index in ayahs.indices {
                let ayahNumber = ayahs[index].number
                if let arabic = arabicMap[ayahNumber], !arabic.isEmpty {
                    ayahs[index].arabicText = arabic
                }
            }
            ayahsBySurah[surahNumber] = ayahs
        }
    }
}


// MARK: - Preview Support

#if DEBUG
extension TranslationStore {
    private struct PreviewData {
        static let surahs: [Surah] = [
            Surah(number: 1, name: "Al-Fatiha", ayahCount: 7)
        ]

        static let albanianAyahs: [Int: [Ayah]] = [
            1: [
                Ayah(number: 1, text: "Me emrin e Allahut, Mëshiruesit, Mëshirëbërësit.", arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"),
                Ayah(number: 2, text: "Falënderimi i qoftë Allahut, Zotit të botëve.", arabicText: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"),
                Ayah(number: 3, text: "Mëshiruesit, Mëshirëbërësit.", arabicText: "الرَّحْمَٰنِ الرَّحِيمِ"),
                Ayah(number: 4, text: "Sunduesit të Ditës së Gjykimit.", arabicText: "مَالِكِ يَوْمِ الدِّينِ"),
                Ayah(number: 5, text: "Vetëm Ty të adhurojmë dhe vetëm prej Teje ndihmë kërkojmë.", arabicText: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ"),
                Ayah(number: 6, text: "Na udhëzo në rrugën e drejtë.", arabicText: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ"),
                Ayah(number: 7, text: "Rrugën e atyre që Ti i ke bekuar, jo të atyre që kanë hidhërimin Tënd, dhe as të atyre që janë të humbur.", arabicText: "صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ")
            ]
        ]

        static let arabicTexts: [Int: [Int: String]] = {
            var mapping: [Int: [Int: String]] = [:]
            for (surah, ayahs) in albanianAyahs {
                mapping[surah] = Dictionary(uniqueKeysWithValues: ayahs.map { ayah in
                    (ayah.number, ayah.arabicText ?? "")
                })
            }
            return mapping
        }()
    }

    private struct PreviewAlbanianLoader: AlbanianQuranLoading {
        func load() throws -> (surahs: [Surah], ayahsBySurah: [Int: [Ayah]]) {
            (PreviewData.surahs, PreviewData.albanianAyahs)
        }
    }

    private final class PreviewTranslationService: TranslationService {
        func fetchSurahMetadata() async throws -> [Surah] { PreviewData.surahs }

        func fetchArabicTextBySurah() async throws -> [Int: [Int: String]] { PreviewData.arabicTexts }
    }

    static func previewStore(preload: Bool = true) -> TranslationStore {
        let service = PreviewTranslationService()
        let store = TranslationStore(service: service, albanianLoader: PreviewAlbanianLoader())

        if preload {
            store.surahs = PreviewData.surahs
            store.ayahsBySurah = PreviewData.albanianAyahs
            store.arabicAyahsBySurah = PreviewData.arabicTexts
            store.hasLoadedInitialData = true
        } else {
            Task { await store.loadInitialData() }
        }

        return store
    }
}

private struct TranslationStorePreviewHost: View {
    @StateObject private var store = TranslationStore.previewStore(preload: false)

    var body: some View {
        List {
            if let ayahs = store.ayahsBySurah[1] {
                Section("Surah 1") {
                    ForEach(ayahs) { ayah in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ayah.text)
                            if let arabic = ayah.arabicText, !arabic.isEmpty {
                                Text(arabic)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text("Loading…")
            }
        }
        .task {
            await store.loadInitialData()
        }
    }
}

#Preview("TranslationStore Surah 1") {
    TranslationStorePreviewHost()
}
#endif
