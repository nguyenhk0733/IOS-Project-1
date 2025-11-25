import Foundation
import Onboarding
import Capture
import Result
import History
import Settings

final class AppViewModel: ObservableObject {
    enum Tab: Hashable {
        case onboarding
        case capture
        case result
        case history
        case settings
    }

    @Published var selectedTab: Tab = .onboarding

    let onboardingViewModel = OnboardingViewModel()
    let captureViewModel = CaptureViewModel()
    let resultViewModel = ResultViewModel()
    let historyViewModel = HistoryViewModel()
    let settingsViewModel = SettingsViewModel()
}
