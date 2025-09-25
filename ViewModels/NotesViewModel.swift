import Foundation
import Combine

@MainActor
final class NotesViewModel: ObservableObject {
    @Published private(set) var groupedNotes: [Int: [Note]] = [:]
    @Published private(set) var sortedSurahNumbers: [Int] = []

    private let notesStore: NotesStore
    private var cancellables: Set<AnyCancellable> = []

    init(notesStore: NotesStore) {
        self.notesStore = notesStore
        notesStore.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                let grouped = notes.groupedBySurah()
                self?.groupedNotes = grouped
                self?.sortedSurahNumbers = grouped.keys.sorted()
            }
            .store(in: &cancellables)
    }

    func notes(for surah: Int) -> [Note] {
        groupedNotes[surah] ?? []
    }
}
