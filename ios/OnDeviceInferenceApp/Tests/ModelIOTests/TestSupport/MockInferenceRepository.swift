// File: Tests/ModelIOTests/TestSupport/MockInferenceRepository.swift
import Foundation
@testable import Shared

final class MockInferenceRepository: InferenceRepositoryProtocol {
    var prepareModelCalled = false
    var runInferenceCalledData: Data?
    var runInferenceResult = InferenceResult(summary: "mock", confidence: 1.0)

    var storedEntries: [HistoryEntry] = []
    var benchmark = InferenceBenchmark()

    func prepareModel() async throws {
        prepareModelCalled = true
    }

    func runInference(on data: Data, saveToHistory: Bool) async throws -> InferenceResult {
        runInferenceCalledData = data
        if saveToHistory {
            _ = try? saveHistory(runInferenceResult, isFavorite: false)
        }
        return runInferenceResult
    }

    func benchmarkMetrics() -> InferenceBenchmark {
        benchmark
    }

    func fetchHistory() throws -> [HistoryEntry] {
        storedEntries
    }

    @discardableResult
    func saveHistory(_ result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry {
        let entry = HistoryEntry(
            id: UUID(),
            timestamp: Date(),
            result: result,
            isFavorite: isFavorite
        )
        storedEntries.insert(entry, at: 0)
        return entry
    }

    func updateFavorite(for id: UUID, isFavorite: Bool) throws {
        guard let index = storedEntries.firstIndex(where: { $0.id == id }) else { return }
        let entry = storedEntries[index]
        storedEntries[index] = HistoryEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            result: entry.result,
            isFavorite: isFavorite
        )
    }
}
