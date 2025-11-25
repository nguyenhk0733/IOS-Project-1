import SwiftUI
import Onboarding
import Capture
import Result
import History
import Settings

@main
struct OnDeviceInferenceApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $appViewModel.selectedTab) {
                OnboardingView(viewModel: appViewModel.onboardingViewModel)
                    .tabItem { Label("Onboarding", systemImage: "sparkles") }
                    .tag(AppViewModel.Tab.onboarding)

                CaptureView(viewModel: appViewModel.captureViewModel)
                    .tabItem { Label("Capture", systemImage: "camera") }
                    .tag(AppViewModel.Tab.capture)

                ResultView(viewModel: appViewModel.resultViewModel)
                    .tabItem { Label("Result", systemImage: "wand.and.stars") }
                    .tag(AppViewModel.Tab.result)

                HistoryView(viewModel: appViewModel.historyViewModel)
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                    .tag(AppViewModel.Tab.history)

                SettingsView(viewModel: appViewModel.settingsViewModel)
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(AppViewModel.Tab.settings)
            }
        }
    }
}
