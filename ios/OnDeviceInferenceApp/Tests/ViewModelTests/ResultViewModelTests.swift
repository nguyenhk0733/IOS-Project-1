import XCTest
@testable import Result
@testable import Shared

@MainActor
final class ResultViewModelTests: XCTestCase {
    func testRunInferenceStoresResult() async {
        let expected = InferenceResult(summary: "ok", confidence: 0.95, metadata: [:], timingMilliseconds: 12)
        let repository = StubInferenceRepository { _ in expected }
        let sut = ResultViewModel(repository: repository)

        await sut.runInference(with: Data("input".utf8))

        XCTAssertEqual(sut.result, expected)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isRunning)
    }

    func testRunInferenceFailureSetsError() async {
        let repository = StubInferenceRepository {
            _ in throw NSError(domain: "test", code: 1)
        }
        let sut = ResultViewModel(repository: repository)

        await sut.runInference(with: Data("input".utf8))

        XCTAssertNil(sut.result)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isRunning)
    }
}
