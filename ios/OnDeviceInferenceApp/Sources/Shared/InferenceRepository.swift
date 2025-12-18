import Foundation

public protocol InferenceRepositoryProtocol {
    func prepareModel() async throws
    func runInference(on data: Data, saveToHistory: Bool) async throws -> InferenceResult
    func benchmarkMetrics() -> InferenceBenchmark
    func fetchHistory() throws -> [HistoryEntry]
    @discardableResult
    func saveHistory(_ result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry
    func updateFavorite(for id: UUID, isFavorite: Bool) throws
}

public extension InferenceRepositoryProtocol {
    func runInference(on data: Data) async throws -> InferenceResult {
        try await runInference(on: data, saveToHistory: false)
    }
}

public final class MockInferenceRepository: InferenceRepositoryProtocol {
    private let inferenceService: OnDeviceInferenceServiceProtocol
    private var entries: [HistoryEntry]

    public init(
        inferenceService: OnDeviceInferenceServiceProtocol = MockOnDeviceInferenceService(),
        entries: [HistoryEntry] = []
    ) {
        self.inferenceService = inferenceService
        self.entries = entries
    }

    public func prepareModel() async throws {
        try await inferenceService.prepareModel()
    }

    public func runInference(on data: Data, saveToHistory: Bool = false) async throws -> InferenceResult {
        let result = try await inferenceService.runInference(on: data)
        if saveToHistory {
            _ = try? saveHistory(result, isFavorite: false)
        }
        return result
    }

    public func benchmarkMetrics() -> InferenceBenchmark {
        inferenceService.benchmarkMetrics()
    }

    public func fetchHistory() throws -> [HistoryEntry] {
        entries
    }

    @discardableResult
    public func saveHistory(_ result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry {
        let entry = HistoryEntry(id: UUID(), timestamp: Date(), result: result, isFavorite: isFavorite)
        entries.insert(entry, at: 0)
        return entry
    }

    public func updateFavorite(for id: UUID, isFavorite: Bool) throws {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries[index]
        entries[index] = HistoryEntry(id: entry.id, timestamp: entry.timestamp, result: entry.result, isFavorite: isFavorite)
    }
}
