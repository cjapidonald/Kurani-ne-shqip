import Foundation
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var surahs: [Surah] = []
    @Published private(set) var lastRead: (surah: Int, ayah: Int)?

    private let translationStore: TranslationStore
    private var cancellables: Set<AnyCancellable> = []

    init(translationStore: TranslationStore) {
        self.translationStore = translationStore
        translationStore.$surahs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] surahs in
                self?.surahs = surahs
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshLastRead()
            }
            .store(in: &cancellables)
        refreshLastRead()
    }

    var filteredSurahs: [Surah] {
        guard !searchText.isEmpty else { return surahs }
        return surahs.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    func refreshLastRead() {
        let surah = UserDefaults.standard.integer(forKey: AppStorageKeys.lastReadSurah)
        let ayah = UserDefaults.standard.integer(forKey: AppStorageKeys.lastReadAyah)
        if surah > 0 && ayah > 0 {
            lastRead = (surah, ayah)
        } else {
            lastRead = nil
        }
    }
}
