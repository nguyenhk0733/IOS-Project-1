import Foundation
import PhotosUI
import Shared
import SwiftUI
import UIKit

public final class CaptureViewModel: ObservableObject {
    @Published public var capturedData: Data?
    @Published public var isShowingCamera = false
    @Published public var isPresentingPhotoPicker = false
    @Published public var isPresentingShareSheet = false
    @Published public private(set) var isPreparingModel = false
    @Published public private(set) var isRunningInference = false
    @Published public private(set) var preparationError: String?
    @Published public private(set) var captureError: String?
    @Published public private(set) var lastCapturedImageURL: URL?
    @Published public private(set) var inferenceResult: InferenceResult?
    @Published public private(set) var shareItems: [Any] = []

    public let permissionsManager: PermissionsManager
    private let inferenceService: OnDeviceInferenceServiceProtocol

    public init(
        inferenceService: OnDeviceInferenceServiceProtocol = OnDeviceInferenceService(),
        permissionsManager: PermissionsManager = PermissionsManager()
    ) {
        self.inferenceService = inferenceService
        self.permissionsManager = permissionsManager
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
    public func refreshPermissions() {
        permissionsManager.refreshStatuses()
    }

    // MARK: - User Intents

    @MainActor
    public func handlePhotoPickerTapped() async {
        switch permissionsManager.photoLibraryStatus {
        case .authorized:
            isPresentingPhotoPicker = true
        case .notDetermined:
            await permissionsManager.requestPhotoLibraryAccess()
            if permissionsManager.photoLibraryStatus == .authorized {
                isPresentingPhotoPicker = true
            }
        case .denied, .restricted:
            break
        }
    }

    public func presentCameraCapture() {
        isShowingCamera = true
    }

    public func handleCameraCapture(at url: URL) {
        isShowingCamera = false
        ingestImage(at: url)
    }

    @MainActor
    public func handlePickedItem(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let preferredExtension =
                    item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                ingestImageData(
                    data,
                    preferredExtension: preferredExtension
                )
            }
        } catch {
            recordCaptureError(error.localizedDescription)
        }
    }

    @MainActor
    public func presentShare(for result: InferenceResult) {
        var items: [Any] = []

        if let data = capturedData, let uiImage = UIImage(data: data) {
            items.append(uiImage)
        } else if let placeholder = UIImage(systemName: "leaf.circle") {
            items.append(placeholder)
        }

        items.append(L10n.formatted("share_summary_format", result.summary, Int(result.confidence * 100)))
        shareItems = items
        isPresentingShareSheet = true
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
