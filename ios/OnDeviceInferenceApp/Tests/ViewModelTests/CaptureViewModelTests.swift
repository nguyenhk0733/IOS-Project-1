import XCTest
@testable import Capture
@testable import Shared

@MainActor
final class CaptureViewModelTests: XCTestCase {
    func testIngestImageDataStoresTemporaryFile() {
        let permissions = StubPermissionsManager()
        let sut = CaptureViewModel(repository: StubInferenceRepository(), permissionsManager: permissions)
        let data = Data("image-data".utf8)

        sut.ingestImageData(data, preferredExtension: "png")

        XCTAssertNotNil(sut.capturedData)
        XCTAssertNotNil(sut.lastCapturedImageURL)
        XCTAssertNil(sut.captureError)
    }

    func testHandlePhotoPickerTappedRequestsPermissionWhenUndetermined() async {
        let permissions = StubPermissionsManager(cameraStatus: .authorized, photoLibraryStatus: .notDetermined)
        permissions.nextPhotoLibraryStatus = .authorized
        let sut = CaptureViewModel(repository: StubInferenceRepository(), permissionsManager: permissions)

        await sut.handlePhotoPickerTapped()

        XCTAssertTrue(sut.isPresentingPhotoPicker)
        XCTAssertEqual(permissions.photoLibraryStatus, .authorized)
    }

    func testRunInferenceOnCaptureSetsResult() async {
        let expected = InferenceResult(summary: "leaf", confidence: 0.8, metadata: [:], timingMilliseconds: 5)
        let repository = StubInferenceRepository {
            _ in expected
        }
        let permissions = StubPermissionsManager()
        let sut = CaptureViewModel(repository: repository, permissionsManager: permissions)
        sut.ingestCapturedData(Data("captured".utf8))

        await sut.runInferenceOnCapture()

        XCTAssertEqual(sut.inferenceResult, expected)
        XCTAssertFalse(sut.isRunningInference)
        XCTAssertNil(sut.captureError)
    }

    func testRunInferenceOnCaptureWithoutDataSetsError() async {
        let permissions = StubPermissionsManager()
        let sut = CaptureViewModel(repository: StubInferenceRepository(), permissionsManager: permissions)

        await sut.runInferenceOnCapture()

        XCTAssertNil(sut.inferenceResult)
        XCTAssertNotNil(sut.captureError)
        XCTAssertFalse(sut.isRunningInference)
    }

    func testRunInferenceOnCaptureHandlesRepositoryFailure() async {
        let repository = StubInferenceRepository()
        repository.shouldThrowOnPrepare = true
        let permissions = StubPermissionsManager()
        let sut = CaptureViewModel(repository: repository, permissionsManager: permissions)
        sut.ingestCapturedData(Data("captured".utf8))

        await sut.runInferenceOnCapture()

        XCTAssertNil(sut.inferenceResult)
        XCTAssertNotNil(sut.captureError)
        XCTAssertFalse(sut.isRunningInference)
    }

    func testPresentShareUsesPlaceholderWhenNoCapture() async {
        let permissions = StubPermissionsManager()
        let sut = CaptureViewModel(repository: StubInferenceRepository(), permissionsManager: permissions)
        let result = InferenceResult(summary: "plant", confidence: 0.7, metadata: [:], timingMilliseconds: nil)

        await sut.presentShare(for: result)

        XCTAssertTrue(sut.isPresentingShareSheet)
        XCTAssertEqual(sut.shareItems.count, 2)
    }
}
