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
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.appPrimary)

                VStack(spacing: 8) {
                    Text("OnDevice Inference")
                        .appTitleStyle()
                        .multilineTextAlignment(.center)
                    Text("Get set up to run models on your device with privacy-first permissions.")
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
                    Text(viewModel.currentIndex + 1 < viewModel.pages.count ? "Next" : "Start")
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
