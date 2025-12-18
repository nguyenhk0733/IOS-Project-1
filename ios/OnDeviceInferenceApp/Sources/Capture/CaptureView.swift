import SwiftUI
import PhotosUI
import Shared

public struct CaptureView: View {
    @ObservedObject var viewModel: CaptureViewModel

    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var shouldAnimateResult = false

    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                L10n.text("capture_description")
                    .appBodyStyle()
                    .multilineTextAlignment(.center)

                // Camera / photo library permission prompts
                permissionStack

                // Actions để chụp / chọn ảnh
                if viewModel.permissionsManager.cameraStatus == .authorized ||
                    viewModel.permissionsManager.photoLibraryStatus == .authorized {
                    captureActions
                }

                // Chuẩn bị model
                if viewModel.isPreparingModel {
                    ProgressView(L10n.string("preparing_model"))
                } else {
                    Button(L10n.string("prepare_model_button")) {
                        Task { await viewModel.prepareModel() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                }

                // Error khi chuẩn bị model
                if let error = viewModel.preparationError {
                    Text(error)
                        .foregroundStyle(.red)
                }

                // Error khi capture
                if let captureError = viewModel.captureError {
                    Text(captureError)
                        .foregroundStyle(.red)
                }

                // Khi đã có dữ liệu ảnh để suy luận
                if viewModel.capturedData != nil {
                    Label {
                        L10n.text("data_ready_label")
                    } icon: {
                        Image(systemName: "checkmark.seal")
                            .accessibilityHidden(true)
                    }
                        .foregroundStyle(.green)

                    // Trạng thái chạy inference
                    if viewModel.isRunningInference {
                        ProgressView(L10n.string("running_inference"))
                    } else {
                        Button(L10n.string("run_inference_button")) {
                            Task { await viewModel.runInferenceOnCapture() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.appPrimary)
                    }

                    // Kết quả suy luận
                    if let inferenceResult = viewModel.inferenceResult {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10n.formatted("prediction_format", inferenceResult.summary))
                            Text(L10n.formatted("confidence_format", Int(inferenceResult.confidence * 100)))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                DiseaseDetailView(result: inferenceResult)
                            } label: {
                                Label {
                                    L10n.text("view_disease_details")
                                } icon: {
                                    Image(systemName: "list.bullet.clipboard")
                                        .accessibilityHidden(true)
                                }
                                    .font(.subheadline)
                            }
                            .padding(.top, 4)

                            Button {
                                viewModel.presentShare(for: inferenceResult)
                            } label: {
                                Label {
                                    L10n.text("share_result")
                                } icon: {
                                    Image(systemName: "square.and.arrow.up")
                                        .accessibilityHidden(true)
                                }
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.appPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appBackground)
                        )
                        // Fade + scale to highlight that a fresh result arrived.
                        .opacity(shouldAnimateResult ? 1 : 0)
                        .scaleEffect(shouldAnimateResult ? 1 : 0.95)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: shouldAnimateResult)
                        .onAppear { animateInferenceResultAppearance() }
                    }
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L10n.string("capture_navigation_title"))
        .onAppear { viewModel.refreshPermissions() }
        .sheet(isPresented: $viewModel.isShowingCamera) {
            CameraCaptureView(permissionsManager: viewModel.permissionsManager) { url in
                viewModel.handleCameraCapture(at: url)
            }
        }
        .sheet(isPresented: $viewModel.isPresentingShareSheet) {
            ShareSheet(activityItems: viewModel.shareItems)
        }
        .photosPicker(
            isPresented: $viewModel.isPresentingPhotoPicker,
            selection: $selectedPickerItem,
            matching: .images
        )
        .onChange(of: selectedPickerItem) { newValue in
            guard let newValue else { return }
            Task { await viewModel.handlePickedItem(newValue) }
        }
        // Kick off the result animation whenever a new inference is set.
        .onChange(of: viewModel.inferenceResult) { newValue in
            if newValue != nil {
                animateInferenceResultAppearance()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    shouldAnimateResult = false
                }
            }
        }
    }

    // MARK: - Permission Views

    @ViewBuilder
    private var permissionStack: some View {
        if viewModel.permissionsManager.cameraStatus != .authorized {
            PermissionRequestView(permissionsManager: viewModel.permissionsManager, type: .camera)
        }

        if viewModel.permissionsManager.photoLibraryStatus != .authorized {
            PermissionRequestView(permissionsManager: viewModel.permissionsManager, type: .photoLibrary)
        }
    }

    // MARK: - Capture Actions

    @ViewBuilder
    private var captureActions: some View {
        VStack(spacing: 12) {
            if viewModel.permissionsManager.cameraStatus == .authorized {
                Button {
                    viewModel.presentCameraCapture()
                } label: {
                    Label {
                        L10n.text("take_photo")
                    } icon: {
                        Image(systemName: "camera.viewfinder")
                            .accessibilityHidden(true)
                    }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)
            }

            if viewModel.permissionsManager.photoLibraryStatus == .authorized {
                Button {
                    Task { await viewModel.handlePhotoPickerTapped() }
                } label: {
                    Label {
                        L10n.text("choose_from_library")
                    } icon: {
                        Image(systemName: "photo")
                            .accessibilityHidden(true)
                    }
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.appPrimary)
            }

            if let lastURL = viewModel.lastCapturedImageURL {
                Text(L10n.formatted("last_capture_saved_format", lastURL.lastPathComponent))
                    .appBodyStyle()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button(L10n.string("mock_capture_input")) {
                viewModel.ingestCapturedData(Data("sample".utf8))
            }
            .buttonStyle(.bordered)
            .tint(.appPrimary)
        }
    }

    /// Resets and replays the result card animation when a new prediction arrives.
    private func animateInferenceResultAppearance() {
        shouldAnimateResult = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            shouldAnimateResult = true
        }
    }
}

#Preview {
    NavigationStack {
        CaptureView(
            viewModel: CaptureViewModel(repository: MockInferenceRepository())
        )
    }
}
