import Combine
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
    let permissionsManager: PermissionsManager

    let onboardingViewModel = OnboardingViewModel()
    let captureViewModel: CaptureViewModel
    let resultViewModel: ResultViewModel
    let historyViewModel: HistoryViewModel
    let settingsViewModel: SettingsViewModel

    private var cancellables = Set<AnyCancellable>()

    init(
        inferenceService: OnDeviceInferenceServiceProtocol = OnDeviceInferenceService(),
        historyStore: HistoryStoring = HistoryStore.shared,
        permissionsManager: PermissionsManager = PermissionsManager()
    ) {
        self.inferenceService = inferenceService
        self.permissionsManager = permissionsManager
        captureViewModel = CaptureViewModel(
            inferenceService: inferenceService,
            permissionsManager: permissionsManager
        )
        resultViewModel = ResultViewModel(inferenceService: inferenceService)
        historyViewModel = HistoryViewModel(store: historyStore)
        settingsViewModel = SettingsViewModel(inferenceService: inferenceService)

        captureViewModel.$inferenceResult
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] result in
                self?.historyViewModel.append(result: result)
            }
            .store(in: &cancellables)

        resultViewModel.$result
            .compactMap { $0 }
            .removeDuplicates()
            .sink { [weak self] result in
                self?.historyViewModel.append(result: result)
            }
            .store(in: &cancellables)
    }
}
