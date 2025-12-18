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

    private let repository: InferenceRepositoryProtocol
    let permissionsManager: PermissionsManager

    let onboardingViewModel = OnboardingViewModel()
    let captureViewModel: CaptureViewModel
    let resultViewModel: ResultViewModel
    let historyViewModel: HistoryViewModel
    let settingsViewModel: SettingsViewModel

    private var cancellables = Set<AnyCancellable>()

    init(
        repository: InferenceRepositoryProtocol = OnDeviceInferenceRepository(),
        permissionsManager: PermissionsManager = PermissionsManager()
    ) {
        self.repository = repository
        self.permissionsManager = permissionsManager
        captureViewModel = CaptureViewModel(
            repository: repository,
            permissionsManager: permissionsManager
        )
        resultViewModel = ResultViewModel(repository: repository)
        historyViewModel = HistoryViewModel(repository: repository)
        settingsViewModel = SettingsViewModel(repository: repository)

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
