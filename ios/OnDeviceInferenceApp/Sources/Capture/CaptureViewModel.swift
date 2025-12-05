import Foundation
import Shared

public final class CaptureViewModel: ObservableObject {
    @Published public var capturedData: Data?
    @Published public private(set) var isPreparingModel = false
    @Published public private(set) var isRunningInference = false
    @Published public private(set) var preparationError: String?
    @Published public private(set) var captureError: String?
    @Published public private(set) var lastCapturedImageURL: URL?
    @Published public private(set) var inferenceResult: InferenceResult?

    private let inferenceService: OnDeviceInferenceServiceProtocol

    public init(inferenceService: OnDeviceInferenceServiceProtocol = OnDeviceInferenceService()) {
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
        captureError = nil
        inferenceResult = nil
    }

    public func ingestImage(at url: URL) {
        do {
            let data = try Data(contentsOf: url)
            lastCapturedImageURL = url
            ingestCapturedData(data)
        } catch {
            captureError = error.localizedDescription
        }
    }

    public func ingestImageData(_ data: Data, preferredExtension: String = "jpg") {
        let fileExtension = preferredExtension.isEmpty ? "jpg" : preferredExtension
        let filename = UUID().uuidString + "." + fileExtension
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            ingestImage(at: url)
        } catch {
            captureError = error.localizedDescription
        }
    }

    public func recordCaptureError(_ message: String) {
        captureError = message
    }

    @MainActor
    public func runInferenceOnCapture() async {
        guard let capturedData else {
            captureError = L10n.string("no_capture_available")
            return
        }

        isRunningInference = true
        captureError = nil

        do {
            try await inferenceService.prepareModel()
            let result = try await inferenceService.runInference(on: capturedData)
            inferenceResult = result
        } catch {
            captureError = error.localizedDescription
        }

        isRunningInference = false
    }
}
