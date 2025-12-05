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
        .init(
            title: L10n.string("onboarding_page_welcome_title"),
            subtitle: L10n.string("onboarding_page_welcome_subtitle"),
            systemImage: "sparkles"
        ),
        .init(
            title: L10n.string("onboarding_page_capture_title"),
            subtitle: L10n.string("onboarding_page_capture_subtitle"),
            systemImage: "camera.viewfinder"
        ),
        .init(
            title: L10n.string("onboarding_page_results_title"),
            subtitle: L10n.string("onboarding_page_results_subtitle"),
            systemImage: "wand.and.stars"
        )
    ]
}
