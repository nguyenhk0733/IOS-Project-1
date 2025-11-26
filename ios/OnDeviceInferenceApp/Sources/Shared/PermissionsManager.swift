import Foundation
import AVFoundation
import Photos
import SwiftUI
import UIKit

public enum PermissionState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

public enum PermissionType: String, CaseIterable {
    case camera
    case photoLibrary

    var title: String {
        switch self {
        case .camera:
            return "Camera Access"
        case .photoLibrary:
            return "Photo Library Access"
        }
    }

    var rationale: String {
        switch self {
        case .camera:
            return "We use your camera to capture images for running on-device inference."
        case .photoLibrary:
            return "We access your photo library so you can select images for analysis."
        }
    }

    var iconName: String {
        switch self {
        case .camera:
            return "camera.viewfinder"
        case .photoLibrary:
            return "photo.on.rectangle"
        }
    }
}

@MainActor
public final class PermissionsManager: ObservableObject {
    @Published public private(set) var cameraStatus: PermissionState
    @Published public private(set) var photoLibraryStatus: PermissionState

    public init() {
        cameraStatus = PermissionsManager.mapCameraStatus(AVCaptureDevice.authorizationStatus(for: .video))
        photoLibraryStatus = PermissionsManager.mapPhotoStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func refreshStatuses() {
        cameraStatus = Self.mapCameraStatus(AVCaptureDevice.authorizationStatus(for: .video))
        photoLibraryStatus = Self.mapPhotoStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    public func requestAccess(for type: PermissionType) async {
        switch type {
        case .camera:
            await requestCameraAccess()
        case .photoLibrary:
            await requestPhotoLibraryAccess()
        }
    }

    public func requestCameraAccess() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .notDetermined else {
            refreshStatuses()
            return
        }

        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = granted ? .authorized : .denied
    }

    public func requestPhotoLibraryAccess() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .notDetermined else {
            refreshStatuses()
            return
        }

        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoLibraryStatus = Self.mapPhotoStatus(newStatus)
    }

    public func status(for type: PermissionType) -> PermissionState {
        switch type {
        case .camera:
            return cameraStatus
        case .photoLibrary:
            return photoLibraryStatus
        }
    }

    public func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private static func mapCameraStatus(_ status: AVAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    private static func mapPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionState {
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

public struct PermissionRequestView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    let type: PermissionType
    var onContinue: () -> Void = {}

    public init(
        permissionsManager: PermissionsManager,
        type: PermissionType,
        onContinue: @escaping () -> Void = {}
    ) {
        self.permissionsManager = permissionsManager
        self.type = type
        self.onContinue = onContinue
    }

    public var body: some View {
        let status = permissionsManager.status(for: type)

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(type.rationale)
                        .appBodyStyle()
                        .multilineTextAlignment(.leading)
                }
            }

            HStack {
                Label(statusDescription(for: status), systemImage: statusIcon(for: status))
                    .foregroundStyle(statusColor(for: status))
                Spacer()
            }

            actionView(for: status)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appBackground.opacity(0.9))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
        )
    }

    @ViewBuilder
    private func actionView(for status: PermissionState) -> some View {
        switch status {
        case .notDetermined:
            Button("Allow") {
                Task { await permissionsManager.requestAccess(for: type) }
            }
            .buttonStyle(.borderedProminent)
            .tint(.appPrimary)
        case .authorized:
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.bordered)
            .tint(.appPrimary)
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 6) {
                Button("Open Settings") {
                    permissionsManager.openSettings()
                }
                .buttonStyle(.borderedProminent)
                .tint(.appPrimary)

                Text("Enable access in Settings to continue using this feature.")
                    .appBodyStyle()
            }
        }
    }

    private func statusDescription(for status: PermissionState) -> String {
        switch status {
        case .authorized:
            return "Access granted"
        case .denied:
            return "Access denied"
        case .restricted:
            return "Access restricted"
        case .notDetermined:
            return "Not requested yet"
        }
    }

    private func statusIcon(for status: PermissionState) -> String {
        switch status {
        case .authorized:
            return "checkmark.seal.fill"
        case .denied, .restricted:
            return "exclamationmark.triangle.fill"
        case .notDetermined:
            return "questionmark.circle"
        }
    }

    private func statusColor(for status: PermissionState) -> Color {
        switch status {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .orange
        case .notDetermined:
            return .gray
        }
    }
}
