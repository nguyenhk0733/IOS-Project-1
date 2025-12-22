// File: Tests/ModelIOTests/TestSupport/MockPermissionsManager.swift
import Foundation
import Combine
@testable import Shared

final class MockPermissionsManager: ObservableObject {
    @Published var cameraStatus: PermissionState
    @Published var photoLibraryStatus: PermissionState

    init(
        cameraStatus: PermissionState = .notDetermined,
        photoLibraryStatus: PermissionState = .notDetermined
    ) {
        self.cameraStatus = cameraStatus
        self.photoLibraryStatus = photoLibraryStatus
    }

    func refreshStatuses() {
        // No-op for tests
    }

    func requestAccess(for type: PermissionType) async {
        switch type {
        case .camera:
            await requestCameraAccess()
        case .photoLibrary:
            await requestPhotoLibraryAccess()
        }
    }

    func requestCameraAccess() async {
        cameraStatus = .authorized
    }

    func requestPhotoLibraryAccess() async {
        photoLibraryStatus = .authorized
    }

    func status(for type: PermissionType) -> PermissionState {
        switch type {
        case .camera:
            return cameraStatus
        case .photoLibrary:
            return photoLibraryStatus
        }
    }

    func openSettings() {
        // No-op for tests
    }
}
