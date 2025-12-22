import XCTest
@testable import App
@testable import Shared

@MainActor
final class AppViewModelTests: XCTestCase {
    func testCaptureInferenceAppendsToHistory() async {
        let repository = StubInferenceRepository { _ in
            InferenceResult(summary: "capture", confidence: 0.6)
        }
        let sut = AppViewModel(repository: repository, permissionsManager: StubPermissionsManager())
        sut.captureViewModel.ingestCapturedData(Data("capture".utf8))

        await sut.captureViewModel.runInferenceOnCapture()

        XCTAssertEqual(sut.historyViewModel.entries.first?.result.summary, "capture")
    }

    func testResultInferenceAppendsToHistory() async {
        let repository = StubInferenceRepository { _ in
            InferenceResult(summary: "result", confidence: 0.7)
        }
        let sut = AppViewModel(repository: repository, permissionsManager: StubPermissionsManager())

        await sut.resultViewModel.runInference(with: Data("result".utf8))

        XCTAssertEqual(sut.historyViewModel.entries.first?.result.summary, "result")
    }
}
