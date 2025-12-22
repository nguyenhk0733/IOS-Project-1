import XCTest
@testable import Settings
@testable import Shared

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testRefreshBenchmarkPullsFromRepository() {
        var benchmark = InferenceBenchmark()
        benchmark.record(durationMilliseconds: 5)
        let repository = StubInferenceRepository(benchmarkValue: benchmark)
        let sut = SettingsViewModel(repository: repository)

        sut.refreshBenchmark()

        XCTAssertEqual(sut.benchmark, benchmark)
    }

    func testRunBenchmarkProbeUpdatesMetrics() async {
        var benchmark = InferenceBenchmark()
        benchmark.record(durationMilliseconds: 10)
        let repository = StubInferenceRepository(
            benchmarkValue: benchmark,
            runInferenceHandler: { _ in InferenceResult(summary: "ok", confidence: 0.9) }
        )
        let sut = SettingsViewModel(repository: repository)

        await sut.runBenchmarkProbe()

        XCTAssertEqual(sut.benchmark.sampleCount, benchmark.sampleCount)
        XCTAssertNil(sut.benchmarkError)
    }

    func testRunBenchmarkProbeWithoutRepositorySetsError() async {
        let sut = SettingsViewModel(repository: nil)

        await sut.runBenchmarkProbe()

        XCTAssertNotNil(sut.benchmarkError)
    }
}
