import Foundation
import SwiftUI

@MainActor
final class TranslationStore: ObservableObject {
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var ayahsBySurah: [Int: [Ayah]] = [:]

    private let service: TranslationService
    private let albanianLoader: AlbanianQuranLoading
    private let quranService: QuranServicing
    private var arabicAyahsBySurah: [Int: [Int: String]] = [:]
    private var hasLoadedInitialData = false
    private var translationWordsCache: [TranslationWordCacheKey: [TranslationWord]] = [:]

    init(
        service: TranslationService = SupabaseTranslationService(),
        albanianLoader: AlbanianQuranLoading = AlbanianQuranLoader(),
        quranService: QuranServicing = QuranService()
    ) {
        self.service = service
        self.albanianLoader = albanianLoader
        self.quranService = quranService
    }

    func loadInitialData() async {
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true

        loadAlbanianText()
#if DEBUG
        logAlbanianAvailability(for: [1, 2], ayahRange: 1...5)
#endif
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

    func translationWords(for surah: Int, ayah: Int) async throws -> [TranslationWord] {
        let key = TranslationWordCacheKey(surah: surah, ayah: ayah)
        if let cached = translationWordsCache[key] {
            return cached
        }

        let words = try await quranService.loadTranslationWords(surah: surah, ayah: ayah)
        let sorted = words.sorted { $0.position < $1.position }
        translationWordsCache[key] = sorted
        return sorted
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
#if DEBUG
        logArabicWordCounts(for: [1, 2], ayahRange: 1...5)
#endif
    }
}

#if DEBUG
private extension TranslationStore {
    func logAlbanianAvailability(for surahNumbers: [Int], ayahRange: ClosedRange<Int>) {
        for surah in surahNumbers {
            for ayahNumber in ayahRange {
                let ayah = ayahsBySurah[surah]?.first(where: { $0.number == ayahNumber })
                let hasText = !(ayah?.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                print("Loaded AL(surah:\(surah), ayah:\(ayahNumber)) available:\(hasText)")
            }
        }
    }

    func logArabicWordCounts(for surahNumbers: [Int], ayahRange: ClosedRange<Int>) {
        for surah in surahNumbers {
            for ayahNumber in ayahRange {
                let ayah = ayahsBySurah[surah]?.first(where: { $0.number == ayahNumber })
                let arabicText = ayah?.arabicText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let wordCount = arabicText.isEmpty ? 0 : arabicText.split { $0.isWhitespace }.count
                print("Loaded AR(surah:\(surah), ayah:\(ayahNumber)) wordCount:\(wordCount)")
            }
        }
    }
}
#endif

private extension TranslationStore {
    struct TranslationWordCacheKey: Hashable {
        let surah: Int
        let ayah: Int
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

        static let translationWords: [TranslationWord] = [
            TranslationWord(surah: 1, ayah: 1, position: 1, arabicWord: "بِسْمِ", albanianWord: "Me"),
            TranslationWord(surah: 1, ayah: 1, position: 2, arabicWord: "ٱللَّهِ", albanianWord: "emrin e Allahut"),
            TranslationWord(surah: 1, ayah: 2, position: 1, arabicWord: "ٱلْحَمْدُ", albanianWord: "Falënderimi"),
            TranslationWord(surah: 1, ayah: 2, position: 2, arabicWord: "لِلَّهِ", albanianWord: "i qoftë Allahut"),
            TranslationWord(surah: 1, ayah: 3, position: 1, arabicWord: "ٱلرَّحْمَٰنِ", albanianWord: "Mëshiruesit"),
            TranslationWord(surah: 1, ayah: 3, position: 2, arabicWord: "ٱلرَّحِيمِ", albanianWord: "Mëshirëbërësit"),
            TranslationWord(surah: 1, ayah: 4, position: 1, arabicWord: "مَالِكِ", albanianWord: "Sunduesit"),
            TranslationWord(surah: 1, ayah: 4, position: 2, arabicWord: "يَوْمِ", albanianWord: "të Ditës"),
            TranslationWord(surah: 1, ayah: 4, position: 3, arabicWord: "الدِّينِ", albanianWord: "së Gjykimit"),
            TranslationWord(surah: 1, ayah: 5, position: 1, arabicWord: "إِيَّاكَ", albanianWord: "Vetëm Ty"),
            TranslationWord(surah: 1, ayah: 5, position: 2, arabicWord: "نَعْبُدُ", albanianWord: "adhurojmë"),
            TranslationWord(surah: 1, ayah: 6, position: 1, arabicWord: "ٱهْدِنَا", albanianWord: "Na udhëzo"),
            TranslationWord(surah: 1, ayah: 7, position: 1, arabicWord: "صِرَاطَ", albanianWord: "Rrugën"),
            TranslationWord(surah: 1, ayah: 7, position: 2, arabicWord: "الَّذِينَ", albanianWord: "e atyre"),
            TranslationWord(surah: 1, ayah: 7, position: 3, arabicWord: "أَنْعَمْتَ", albanianWord: "që i ke bekuar")
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

    private final class PreviewQuranService: QuranServicing {
        func loadTranslationWords(surah: Int, ayah: Int?) async throws -> [TranslationWord] {
            let words = PreviewData.translationWords.filter { $0.surah == surah }
            guard let ayah else { return words }
            return words.filter { $0.ayah == ayah }
        }

        func rebuildAlbanianAyah(surah: Int, ayah: Int) async throws -> String {
            if let ayah = PreviewData.albanianAyahs[surah]?.first(where: { $0.number == ayah }) {
                return ayah.text
            }
            let words = try await loadTranslationWords(surah: surah, ayah: ayah)
            guard !words.isEmpty else { return "" }
            return words.sorted { $0.position < $1.position }.map(\.albanianWord).joined(separator: " ")
        }

        func getMyNotesForSurah(surah: Int) async throws -> [NoteRow] { [] }

        func upsertMyNote(surah: Int, ayah: Int, albanianText: String, note: String) async throws {}

        func isFavorite(surah: Int, ayah: Int) async throws -> Bool { false }

        func toggleFavorite(surah: Int, ayah: Int) async throws {}

        func loadMyFavouritesView() async throws -> [FavoriteViewRow] { [] }

        func loadArabicDictionary() async throws -> [ArabicDictionaryEntry] { [] }
    }

    static func previewStore(preload: Bool = true) -> TranslationStore {
        let service = PreviewTranslationService()
        let store = TranslationStore(
            service: service,
            albanianLoader: PreviewAlbanianLoader(),
            quranService: PreviewQuranService()
        )

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
