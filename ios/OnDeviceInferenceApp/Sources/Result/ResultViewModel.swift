import Foundation
import Shared

public final class ResultViewModel: ObservableObject {
    @Published public private(set) var result: InferenceResult? = nil
    @Published public private(set) var isRunning = false
    @Published public private(set) var errorMessage: String? = nil

    private let inferenceService: OnDeviceInferenceServiceProtocol

    public init(inferenceService: OnDeviceInferenceServiceProtocol = MockOnDeviceInferenceService()) {
        self.inferenceService = inferenceService
    }

    @MainActor
    public func runInference(with data: Data) async {
        isRunning = true
        errorMessage = nil
        do {
            result = try await inferenceService.runInference(on: data)
        } catch {
            errorMessage = error.localizedDescription
        }
        isRunning = false
    }
}
