import SwiftUI
import Shared

public struct ResultView: View {
    @ObservedObject var viewModel: ResultViewModel

    public init(viewModel: ResultViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Run inference on captured data and inspect results.")
                .multilineTextAlignment(.center)
                .padding()

            if viewModel.isRunning {
                ProgressView("Running inference…")
            } else {
                Button("Run Mock Inference") {
                    Task { await viewModel.runInference(with: Data("sample".utf8)) }
                }
                .buttonStyle(.borderedProminent)
            }

            if let result = viewModel.result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary: \(result.summary)")
                    Text("Confidence: \(Int(result.confidence * 100))%")
                    if let timing = result.timingMilliseconds {
                        Text(String(format: "Inference time: %.1f ms", timing))
                    }
                    if !result.metadata.isEmpty {
                        Text("Metadata: \(result.metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
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
        .navigationTitle("Result")
    }
}

#Preview {
    NavigationStack {
        ResultView(viewModel: ResultViewModel())
    }
}
