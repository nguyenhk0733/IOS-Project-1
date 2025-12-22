import XCTest
@testable import Shared

final class OnDeviceInferenceServiceTests: XCTestCase {

    private let dummyData = Data([0x00, 0x01, 0x02])

    // MARK: - Smoke & error-path tests (PASS)

    func testPrepareModelThrowsWhenModelIsMissing() async {
        let service = OnDeviceInferenceService(modelName: "NonexistentModel")

        do {
            try await service.prepareModel()
            XCTFail("Expected modelNotFound error")
        } catch let error as OnDeviceInferenceError {
            switch error {
            case .modelNotFound:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected modelNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testRunningInferenceWithoutPreparingThrowsModelNotPrepared() async {
        let service = OnDeviceInferenceService(modelName: "NonexistentModel")

        do {
            _ = try await service.runInference(on: dummyData)
            XCTFail("Expected modelNotPrepared error")
        } catch let error as OnDeviceInferenceError {
            switch error {
            case .modelNotPrepared:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected modelNotPrepared, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Benchmark tests (PASS)

    func testBenchmarkMaintainsSlidingWindowAndAverage() {
        var benchmark = InferenceBenchmark()

        for i in 1...25 {
            benchmark.record(durationMilliseconds: Double(i))
        }

        // Sliding window keeps last 20 samples
        XCTAssertEqual(benchmark.sampleCount, 20)

        // averageMilliseconds is Optional -> unwrap before asserting
        XCTAssertNotNil(benchmark.averageMilliseconds)
        guard let average = benchmark.averageMilliseconds else {
            XCTFail("Expected averageMilliseconds to be set")
            return
        }
        XCTAssertEqual(average, 15.5, accuracy: 0.001)

        // lastRunMilliseconds is Optional -> unwrap before asserting
        XCTAssertNotNil(benchmark.lastRunMilliseconds)
        guard let last = benchmark.lastRunMilliseconds else {
            XCTFail("Expected lastRunMilliseconds to be set")
            return
        }
        XCTAssertEqual(last, 25)
    }

    // MARK: - Intentional failing tests (EXPECTED FAIL)

    /// ❌ Expected to fail:
    /// runInference currently reports `.modelNotPrepared`, not `.modelNotFound`
    func testRunInferenceReportsModelNotFoundWithoutPreparation() async {
        let service = OnDeviceInferenceService(modelName: "NonexistentModel")

        do {
            _ = try await service.runInference(on: dummyData)
            XCTFail("Expected error")
        } catch let error as OnDeviceInferenceError {
            // ❌ Intentional mismatch
            switch error {
            case .modelNotFound:
                XCTAssertTrue(true)
            default:
                XCTFail("Intentional failure: expected modelNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    /// ❌ Expected to fail:
    /// identical samples are currently treated as stable
    func testBenchmarkStabilityRemainsUnstableForIdenticalSamples() {
        var benchmark = InferenceBenchmark()
        benchmark.record(durationMilliseconds: 10)
        benchmark.record(durationMilliseconds: 10)
        benchmark.record(durationMilliseconds: 10)

        // ❌ Intentional failure
        XCTAssertFalse(benchmark.isStable)
    }
}
