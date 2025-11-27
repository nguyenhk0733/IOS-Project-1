import SwiftUI
import Shared

public struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var permissionsManager: PermissionsManager
    @StateObject private var cameraManager = CameraSessionManager()

    private let onPhotoCaptured: (URL) -> Void

    public init(permissionsManager: PermissionsManager, onPhotoCaptured: @escaping (URL) -> Void) {
        self.permissionsManager = permissionsManager
        self.onPhotoCaptured = onPhotoCaptured
    }

    public var body: some View {
        ZStack {
            if permissionsManager.cameraStatus == .authorized {
                CameraPreviewView(manager: cameraManager)
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 12) {
                            if let error = cameraManager.error?.localizedDescription {
                                Text(error)
                                    .padding(10)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }

                            Button(action: cameraManager.capturePhoto) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 78, height: 78)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.2), lineWidth: 6)
                                    )
                                    .shadow(radius: 8)
                            }
                            .padding(.bottom, 32)
                        }
                    }
            } else {
                Color.black.ignoresSafeArea()
                PermissionRequestView(permissionsManager: permissionsManager, type: .camera) { handlePermissionChange() }
                    .padding()
            }
        }
        .onAppear { handlePermissionChange() }
        .onDisappear { cameraManager.stopSession() }
        .onChange(of: cameraManager.lastCapturedImageURL) { newValue in
            guard let newValue else { return }
            onPhotoCaptured(newValue)
            dismiss()
        }
    }

    private func handlePermissionChange() {
        switch permissionsManager.cameraStatus {
        case .authorized:
            cameraManager.startSession()
        case .notDetermined:
            Task {
                await permissionsManager.requestCameraAccess()
                if permissionsManager.cameraStatus == .authorized {
                    cameraManager.startSession()
                }
            }
        case .denied, .restricted:
            break
        }
    }
}

#Preview {
    CameraCaptureView(permissionsManager: PermissionsManager()) { _ in }
}
