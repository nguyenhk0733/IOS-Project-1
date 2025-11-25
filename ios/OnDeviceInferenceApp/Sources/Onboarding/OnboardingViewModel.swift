import Foundation
import Shared

public final class OnboardingViewModel: ObservableObject {
    @Published public private(set) var pages: [OnboardingPage]
    @Published public var currentIndex: Int

    public init(pages: [OnboardingPage] = OnboardingPage.defaultPages, currentIndex: Int = 0) {
        self.pages = pages
        self.currentIndex = currentIndex
    }

    public func advance() {
        guard currentIndex + 1 < pages.count else { return }
        currentIndex += 1
    }
}

public struct OnboardingPage: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let systemImage: String

    public init(title: String, subtitle: String, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    public static let defaultPages: [OnboardingPage] = [
        .init(title: "Welcome", subtitle: "Run models entirely on-device.", systemImage: "sparkles"),
        .init(title: "Capture", subtitle: "Collect input safely and privately.", systemImage: "camera.viewfinder"),
        .init(title: "Results", subtitle: "Review inference output instantly.", systemImage: "wand.and.stars")
    ]
}
