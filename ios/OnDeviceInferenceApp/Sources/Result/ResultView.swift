import SwiftUI
import Shared

public struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel

    public init(viewModel: ResultViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            L10n.text("result_description")
                .multilineTextAlignment(.center)
                .padding()

            if viewModel.isRunning {
                ProgressView(L10n.string("running_inference"))
            } else {
                Button(L10n.string("run_mock_inference")) {
                    Task { await viewModel.runInference(with: Data("sample".utf8)) }
                }
                .buttonStyle(.borderedProminent)
            }

            if let result = viewModel.result {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.formatted("summary_format", result.summary))
                    Text(L10n.formatted("confidence_format", Int(result.confidence * 100)))
                    if let timing = result.timingMilliseconds {
                        Text(L10n.formatted("inference_time_format", timing))
                    }
                    if !result.metadata.isEmpty {
                        Text(
                            L10n.formatted(
                                "metadata_format",
                                result.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                            )
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(L10n.string("result_navigation_title"))
    }
}

#Preview {
    NavigationStack {
        ResultView(viewModel: ResultViewModel(repository: MockInferenceRepository()))
    }
}
