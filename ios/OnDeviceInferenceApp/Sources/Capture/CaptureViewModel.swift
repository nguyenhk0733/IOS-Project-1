import Foundation
import Shared

public final class CaptureViewModel: ObservableObject {
    @Published public var capturedData: Data?
    @Published public private(set) var isPreparingModel = false
    @Published public private(set) var preparationError: String?

    private let inferenceService: OnDeviceInferenceServiceProtocol

    public init(inferenceService: OnDeviceInferenceServiceProtocol = MockOnDeviceInferenceService()) {
        self.inferenceService = inferenceService
    }

    @MainActor
    public func prepareModel() async {
        isPreparingModel = true
        preparationError = nil
        do {
            try await inferenceService.prepareModel()
        } catch {
            preparationError = error.localizedDescription
        }
        isPreparingModel = false
    }

    public func ingestCapturedData(_ data: Data) {
        capturedData = data
    }
}
