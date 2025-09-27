import Foundation
import Combine

@MainActor
final class ReadingProgressStore: ObservableObject {
    @Published private(set) var highestReadAyahBySurah: [Int: Int]

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
        if let data = defaults.data(forKey: AppStorageKeys.readingProgress),
           let decoded = try? decoder.decode([Int: Int].self, from: data) {
            highestReadAyahBySurah = decoded
        } else {
            highestReadAyahBySurah = [:]
        }
    }

    func highestAyahRead(for surah: Int) -> Int {
        highestReadAyahBySurah[surah] ?? 0
    }

    func progress(for surah: Int, totalAyahs: Int) -> Double {
        guard totalAyahs > 0 else { return 0 }
        let highest = max(0, min(highestAyahRead(for: surah), totalAyahs))
        return Double(highest) / Double(totalAyahs)
    }

    func updateHighestAyah(_ ayah: Int, for surah: Int, totalAyahs: Int) {
        let clampedAyah = max(0, min(ayah, totalAyahs))
        guard clampedAyah > (highestReadAyahBySurah[surah] ?? 0) else { return }
        highestReadAyahBySurah[surah] = clampedAyah
        persist()
    }

    func reset() {
        highestReadAyahBySurah = [:]
        defaults.removeObject(forKey: AppStorageKeys.readingProgress)
        defaults.removeObject(forKey: AppStorageKeys.lastReadSurah)
        defaults.removeObject(forKey: AppStorageKeys.lastReadAyah)
    }

    private func persist() {
        if let data = try? encoder.encode(highestReadAyahBySurah) {
            defaults.set(data, forKey: AppStorageKeys.readingProgress)
        }
    }
}

#if DEBUG
extension ReadingProgressStore {
    static func previewStore() -> ReadingProgressStore {
        // Use a separate suite to avoid polluting real defaults during previews
        let defaults = UserDefaults(suiteName: "ReadingProgressStore.preview") ?? .standard
        return ReadingProgressStore(userDefaults: defaults)
    }
}
#endif
