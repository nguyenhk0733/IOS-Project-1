import Foundation

public protocol OnDeviceInferenceServiceProtocol {
    func prepareModel() async throws
    func runInference(on data: Data) async throws -> InferenceResult
}

public struct InferenceResult: Sendable, Equatable {
    public let summary: String
    public let confidence: Double
    public let metadata: [String: String]

    public init(summary: String, confidence: Double, metadata: [String: String] = [:]) {
        self.summary = summary
        self.confidence = confidence
        self.metadata = metadata
    }
}

public final class MockOnDeviceInferenceService: OnDeviceInferenceServiceProtocol {
    public init() {}

    public func prepareModel() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    public func runInference(on data: Data) async throws -> InferenceResult {
        try await Task.sleep(nanoseconds: 300_000_000)
        return InferenceResult(
            summary: "Sample output",
            confidence: 0.9,
            metadata: ["source": "mock"]
        )
    }
}
