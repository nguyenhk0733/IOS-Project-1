import XCTest
@testable import Onboarding

final class OnboardingViewModelTests: XCTestCase {
    func testAdvanceMovesForwardUntilEnd() {
        let sut = OnboardingViewModel()

        sut.advance()
        XCTAssertEqual(sut.currentIndex, 1)

        sut.advance()
        XCTAssertEqual(sut.currentIndex, 2)
    }

    func testAdvanceDoesNotExceedPageCount() {
        let sut = OnboardingViewModel(pages: [.init(title: "a", subtitle: "b", systemImage: "bolt")], currentIndex: 0)

        sut.advance()
        XCTAssertEqual(sut.currentIndex, 0)
    }
}
