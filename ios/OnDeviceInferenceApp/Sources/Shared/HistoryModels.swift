import Foundation

public protocol HistoryStoring {
    func fetchEntries() throws -> [HistoryEntry]
    @discardableResult
    func save(result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry
    func updateFavorite(for id: UUID, isFavorite: Bool) throws
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
