import Foundation
import Shared

public final class HistoryViewModel: ObservableObject {
    @Published public private(set) var entries: [HistoryEntry]

    public init(entries: [HistoryEntry] = []) {
        self.entries = entries
    }

    public func append(result: InferenceResult) {
        let entry = HistoryEntry(id: UUID(), timestamp: Date(), result: result)
        entries.insert(entry, at: 0)
    }
}

public struct HistoryEntry: Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let result: InferenceResult
}
