import Foundation
import Shared
import History

final class OnDeviceInferenceRepository: InferenceRepositoryProtocol {
    private let inferenceService: OnDeviceInferenceServiceProtocol
    private let historyStore: HistoryStoring

    init(
        inferenceService: OnDeviceInferenceServiceProtocol = OnDeviceInferenceService(),
        historyStore: HistoryStoring = HistoryStore.shared
    ) {
        self.inferenceService = inferenceService
        self.historyStore = historyStore
    }

    func prepareModel() async throws {
        try await inferenceService.prepareModel()
    }

    func runInference(on data: Data, saveToHistory: Bool = false) async throws -> InferenceResult {
        let result = try await inferenceService.runInference(on: data)
        if saveToHistory {
            _ = try? historyStore.save(result: result, isFavorite: false)
        }
        return result
    }

    func benchmarkMetrics() -> InferenceBenchmark {
        inferenceService.benchmarkMetrics()
    }

    func fetchHistory() throws -> [HistoryEntry] {
        try historyStore.fetchEntries()
    }

    @discardableResult
    func saveHistory(_ result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry {
        try historyStore.save(result: result, isFavorite: isFavorite)
    }

    func updateFavorite(for id: UUID, isFavorite: Bool) throws {
        try historyStore.updateFavorite(for: id, isFavorite: isFavorite)
    }
}
