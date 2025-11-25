import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 12) {
                        Image(systemName: page.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(page.title)
                            .font(.title2)
                            .bold()
                        Text(page.subtitle)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page)

            Button(action: viewModel.advance) {
                Text(viewModel.currentIndex + 1 < viewModel.pages.count ? "Next" : "Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(viewModel: OnboardingViewModel())
}
