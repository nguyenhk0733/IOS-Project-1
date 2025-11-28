import SwiftUI
import PhotosUI
import Shared

public struct CaptureView: View {
    @ObservedObject var viewModel: CaptureViewModel
    @ObservedObject var permissionsManager: PermissionsManager

    @State private var isShowingCamera = false
    @State private var isPresentingPhotoPicker = false
    @State private var selectedPickerItem: PhotosPickerItem?

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

                permissionStack

                if permissionsManager.cameraStatus == .authorized || permissionsManager.photoLibraryStatus == .authorized {
                    captureActions
                }

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

                if let captureError = viewModel.captureError {
                    Text(captureError)
                        .foregroundStyle(.red)
                }

                if viewModel.capturedData != nil {
                    Label("Data ready for inference", systemImage: "checkmark.seal")
                        .foregroundStyle(.green)

                    if viewModel.isRunningInference {
                        ProgressView("Running inference…")
                    } else {
                        Button("Run On-Device Inference") {
                            Task { await viewModel.runInferenceOnCapture() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPrimary)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                }

                    if let inferenceResult = viewModel.inferenceResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prediction: \(inferenceResult.summary)")
                            Text("Confidence: \(Int(inferenceResult.confidence * 100))%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appBackground)
                        )
                    }
                if let error = viewModel.preparationError {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if let captureError = viewModel.captureError {
                    Text(captureError)
                        .foregroundStyle(.red)
                }

                if viewModel.capturedData != nil {
                    Label("Data ready for inference", systemImage: "checkmark.seal")
                        .foregroundStyle(.green)
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Capture")
        .onAppear { permissionsManager.refreshStatuses() }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureView(permissionsManager: permissionsManager) { url in
                viewModel.ingestImage(at: url)
            }
        }
        .photosPicker(isPresented: $isPresentingPhotoPicker, selection: $selectedPickerItem, matching: .images)
        .onChange(of: selectedPickerItem) { newValue in
            guard let newValue else { return }
            Task { await loadPickedItem(newValue) }
        }
    }

    @ViewBuilder
    private var permissionStack: some View {
        if permissionsManager.cameraStatus != .authorized {
            PermissionRequestView(permissionsManager: permissionsManager, type: .camera)
        }

        if permissionsManager.photoLibraryStatus != .authorized {
            PermissionRequestView(permissionsManager: permissionsManager, type: .photoLibrary)
        }
    }

    @ViewBuilder
    private var captureActions: some View {
        VStack(spacing: 12) {
            if permissionsManager.cameraStatus == .authorized {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
            }

            if permissionsManager.photoLibraryStatus == .authorized {
                Button {
                    handlePhotoPickerTapped()
                } label: {
                    Label("Choose from Library", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }

            if let lastURL = viewModel.lastCapturedImageURL {
                Text("Last capture saved to: \(lastURL.lastPathComponent)")
                    .appBodyStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button("Mock Capture Input") {
                viewModel.ingestCapturedData(Data("sample".utf8))
            }
            .buttonStyle(.bordered)
            .tint(.appPrimary)
        }
    }

    private func handlePhotoPickerTapped() {
        switch permissionsManager.photoLibraryStatus {
        case .authorized:
            isPresentingPhotoPicker = true
        case .notDetermined:
            Task {
                await permissionsManager.requestPhotoLibraryAccess()
                if permissionsManager.photoLibraryStatus == .authorized {
                    isPresentingPhotoPicker = true
                }
            }
        case .denied, .restricted:
            break
        }
    }

    private func loadPickedItem(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                let preferredExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                await MainActor.run {
                    viewModel.ingestImageData(data, preferredExtension: preferredExtension)
                }
            }
        } catch {
            await MainActor.run {
                viewModel.recordCaptureError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView(viewModel: CaptureViewModel(), permissionsManager: PermissionsManager())
    }
}
