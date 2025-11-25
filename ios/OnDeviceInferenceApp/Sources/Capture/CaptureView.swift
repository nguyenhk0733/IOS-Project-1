import SwiftUI

public struct CaptureView: View {
    @ObservedObject var viewModel: CaptureViewModel

    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("Capture input to run on-device inference.")
                .multilineTextAlignment(.center)
                .padding()

            if viewModel.isPreparingModel {
                ProgressView("Preparing model…")
            } else {
                Button("Prepare Model") {
                    Task { await viewModel.prepareModel() }
                }
                .buttonStyle(.borderedProminent)
            }

            if let error = viewModel.preparationError {
                Text(error)
                    .foregroundStyle(.red)
            }

            Button("Mock Capture Input") {
                viewModel.ingestCapturedData(Data("sample".utf8))
            }
            .buttonStyle(.bordered)

            if viewModel.capturedData != nil {
                Label("Data ready for inference", systemImage: "checkmark.seal")
                    .foregroundStyle(.green)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Capture")
    }
}

#Preview {
    NavigationStack {
        CaptureView(viewModel: CaptureViewModel())
    }
}
