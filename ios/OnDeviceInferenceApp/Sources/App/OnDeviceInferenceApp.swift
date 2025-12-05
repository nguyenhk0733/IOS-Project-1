import SwiftUI
import Onboarding
import Capture
import Result
import History
import Settings
import Shared

@main
struct OnDeviceInferenceApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var permissionsManager = PermissionsManager()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $appViewModel.selectedTab) {
                NavigationStack {
                    OnboardingView(
                        viewModel: appViewModel.onboardingViewModel,
                        permissionsManager: permissionsManager
                    )
                }
                .tabItem {
                    Label {
                        L10n.text("tab_onboarding")
                    } icon: {
                        Image(systemName: "sparkles")
                            .accessibilityHidden(true)
                    }
                }
                .tag(AppViewModel.Tab.onboarding)

                NavigationStack {
                    CaptureView(
                        viewModel: appViewModel.captureViewModel,
                        permissionsManager: permissionsManager
                    )
                }
                .tabItem {
                    Label {
                        L10n.text("tab_capture")
                    } icon: {
                        Image(systemName: "camera")
                            .accessibilityHidden(true)
                    }
                }
                .tag(AppViewModel.Tab.capture)

                NavigationStack {
                    ResultView(viewModel: appViewModel.resultViewModel)
                }
                .tabItem {
                    Label {
                        L10n.text("tab_result")
                    } icon: {
                        Image(systemName: "wand.and.stars")
                            .accessibilityHidden(true)
                    }
                }
                .tag(AppViewModel.Tab.result)

                NavigationStack {
                    HistoryView(viewModel: appViewModel.historyViewModel)
                }
                .tabItem {
                    Label {
                        L10n.text("tab_history")
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .accessibilityHidden(true)
                    }
                }
                .tag(AppViewModel.Tab.history)

                NavigationStack {
                    SettingsView(viewModel: appViewModel.settingsViewModel)
                }
                .tabItem {
                    Label {
                        L10n.text("tab_settings")
                    } icon: {
                        Image(systemName: "gearshape")
                            .accessibilityHidden(true)
                    }
                }
                .tag(AppViewModel.Tab.settings)
            }
            .tint(.appPrimary)
            .background(Color.appBackground.ignoresSafeArea())
        }
    }
}
