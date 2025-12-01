import Foundation
import Onboarding
import Capture
import Result
import History
import Settings
import Shared

final class AppViewModel: ObservableObject {
    enum Tab: Hashable {
        case onboarding
        case capture
        case result
        case history
        case settings
    }

    @Published var selectedTab: Tab = .onboarding

    private let inferenceService: OnDeviceInferenceServiceProtocol

    let onboardingViewModel = OnboardingViewModel()
    let captureViewModel: CaptureViewModel
    let resultViewModel: ResultViewModel
    let historyViewModel = HistoryViewModel()
    let settingsViewModel: SettingsViewModel

    init(inferenceService: OnDeviceInferenceServiceProtocol = OnDeviceInferenceService()) {
        self.inferenceService = inferenceService
        captureViewModel = CaptureViewModel(inferenceService: inferenceService)
        resultViewModel = ResultViewModel(inferenceService: inferenceService)
        settingsViewModel = SettingsViewModel(inferenceService: inferenceService)
    }
}
