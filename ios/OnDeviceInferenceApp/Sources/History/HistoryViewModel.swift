import Foundation
import Shared

public protocol HistoryStoring {
    func fetchEntries() throws -> [HistoryEntry]
    @discardableResult
    func save(result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry
    func updateFavorite(for id: UUID, isFavorite: Bool) throws
}

public final class HistoryViewModel: ObservableObject {
    @Published public private(set) var entries: [HistoryEntry]
    @Published public var errorMessage: String?

    private let store: HistoryStoring

    public init(entries: [HistoryEntry] = [], store: HistoryStoring = HistoryStore.shared) {
        self.entries = entries
        self.store = store
        if entries.isEmpty {
            loadPersistedEntries()
        }
    }

    public func loadPersistedEntries() {
        do {
            entries = try store.fetchEntries()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func append(result: InferenceResult) {
        do {
            let entry = try store.save(result: result, isFavorite: false)
            entries.insert(entry, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleFavorite(for entry: HistoryEntry) {
        let newValue = !entry.isFavorite
        do {
            try store.updateFavorite(for: entry.id, isFavorite: newValue)
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

public struct HistoryEntry: Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let result: InferenceResult
    public let isFavorite: Bool

    public init(id: UUID, timestamp: Date, result: InferenceResult, isFavorite: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.result = result
        self.isFavorite = isFavorite
    }
}
