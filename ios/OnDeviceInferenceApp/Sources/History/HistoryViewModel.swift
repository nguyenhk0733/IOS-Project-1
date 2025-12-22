import Foundation
import Shared

public final class HistoryViewModel: ObservableObject {
    @Published public private(set) var entries: [HistoryEntry]
    @Published public var errorMessage: String?

    private let repository: InferenceRepositoryProtocol

    public init(entries: [HistoryEntry] = [], repository: InferenceRepositoryProtocol) {
        self.entries = entries
        self.repository = repository
        if entries.isEmpty {
            loadPersistedEntries()
        }
    }

    public func loadPersistedEntries() {
        do {
            entries = try repository
                .fetchHistory()
                .sorted(by: { $0.timestamp > $1.timestamp })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func append(result: InferenceResult) {
        do {
            let entry = try repository.saveHistory(result, isFavorite: false)
            entries.insert(entry, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleFavorite(for entry: HistoryEntry) {
        let newValue = !entry.isFavorite
        do {
            try repository.updateFavorite(for: entry.id, isFavorite: newValue)
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                let updated = HistoryEntry(
                    id: entry.id,
                    timestamp: entry.timestamp,
                    result: entry.result,
                    isFavorite: newValue
                )
                entries[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
