import SwiftUI
import Shared

public struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @ObservedObject var permissionsManager: PermissionsManager

    public init(viewModel: OnboardingViewModel, permissionsManager: PermissionsManager) {
        self.viewModel = viewModel
        self.permissionsManager = permissionsManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(.largeTitle, weight: .semibold))
                    .foregroundStyle(.appPrimary)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    L10n.text("onboarding_title")
                        .appTitleStyle()
                        .multilineTextAlignment(.center)
                    L10n.text("onboarding_description")
                        .appBodyStyle()
                        .multilineTextAlignment(.center)
                }

                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 12) {
                            Image(systemName: page.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(.appPrimary)
                            Text(page.title)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(page.subtitle)
                                .appBodyStyle()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .tag(index)
                    }
                }
                .frame(height: 240)
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(action: viewModel.advance) {
                    Text(
                        viewModel.currentIndex + 1 < viewModel.pages.count
                            ? L10n.string("onboarding_next")
                            : L10n.string("onboarding_start")
                    )
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
                .padding(.horizontal)

                VStack(spacing: 12) {
                    PermissionRequestView(permissionsManager: permissionsManager, type: .camera)
                    PermissionRequestView(permissionsManager: permissionsManager, type: .photoLibrary)
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear { permissionsManager.refreshStatuses() }
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(), permissionsManager: PermissionsManager())
}
