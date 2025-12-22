import XCTest
@testable import History
@testable import Shared

final class HistoryViewModelTests: XCTestCase {
    func testLoadsEntriesOnInit() {
        let repository = StubInferenceRepository(storedEntries: [
            HistoryEntry(id: UUID(), timestamp: Date(), result: .init(summary: "a", confidence: 0.5), isFavorite: false)
        ])

        let sut = HistoryViewModel(repository: repository)

        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testAppendAddsNewEntryToTop() {
        let repository = StubInferenceRepository()
        let sut = HistoryViewModel(entries: [], repository: repository)
        let result = InferenceResult(summary: "new", confidence: 0.8)

        sut.append(result: result)

        XCTAssertEqual(sut.entries.first?.result, result)
        XCTAssertNil(sut.errorMessage)
    }

    func testToggleFavoriteUpdatesEntry() {
        let result = InferenceResult(summary: "item", confidence: 0.3)
        let entry = HistoryEntry(id: UUID(), timestamp: Date(), result: result, isFavorite: false)
        let repository = StubInferenceRepository(storedEntries: [entry])
        let sut = HistoryViewModel(entries: [entry], repository: repository)

        sut.toggleFavorite(for: entry)

        XCTAssertEqual(sut.entries.first?.isFavorite, true)
        XCTAssertNil(sut.errorMessage)
    }
}
