import SwiftUI
import Shared

public struct CaptureView: View {
    @ObservedObject var viewModel: CaptureViewModel
    @ObservedObject var permissionsManager: PermissionsManager

    public init(viewModel: CaptureViewModel, permissionsManager: PermissionsManager) {
        self.viewModel = viewModel
        self.permissionsManager = permissionsManager
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Capture input to run on-device inference.")
                    .appBodyStyle()
                    .multilineTextAlignment(.center)

                if permissionsManager.cameraStatus != .authorized {
                    PermissionRequestView(permissionsManager: permissionsManager, type: .camera)
                }

                if permissionsManager.photoLibraryStatus != .authorized {
                    PermissionRequestView(permissionsManager: permissionsManager, type: .photoLibrary)
                }

                if permissionsManager.cameraStatus == .authorized && permissionsManager.photoLibraryStatus == .authorized {
                    if viewModel.isPreparingModel {
                        ProgressView("Preparing model…")
                    } else {
                        Button("Prepare Model") {
                            Task { await viewModel.prepareModel() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPrimary)
                    }

                    if let error = viewModel.preparationError {
                        Text(error)
                            .foregroundStyle(.red)
                    }

                    Button("Mock Capture Input") {
                        viewModel.ingestCapturedData(Data("sample".utf8))
                    }
                    .buttonStyle(.bordered)
                    .tint(.appPrimary)

                    if viewModel.capturedData != nil {
                        Label("Data ready for inference", systemImage: "checkmark.seal")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Capture")
        .onAppear { permissionsManager.refreshStatuses() }
    }
}

#Preview {
    NavigationStack {
        CaptureView(viewModel: CaptureViewModel(), permissionsManager: PermissionsManager())
    }
}
