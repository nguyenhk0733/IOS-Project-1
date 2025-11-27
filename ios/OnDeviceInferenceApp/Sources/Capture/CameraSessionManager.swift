import AVFoundation
import SwiftUI

public enum CameraError: LocalizedError, Equatable {
    case configurationFailed(String)
    case captureFailed(String)

    public var errorDescription: String? {
        switch self {
        case .configurationFailed(let message):
            return message
        case .captureFailed(let message):
            return message
        }
    }
}

public final class CameraSessionManager: NSObject, ObservableObject {
    @Published public private(set) var lastCapturedImageURL: URL?
    @Published public private(set) var error: CameraError?

    public let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private var currentDevice: AVCaptureDevice?

    public override init() {
        super.init()
    }

    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureSession()
            }

            guard self.error == nil else { return }

            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    public func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.error == nil else { return }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            settings.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    public func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }

            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                }

                device.unlockForConfiguration()
            } catch {
                DispatchQueue.main.async {
                    self.error = .configurationFailed("Unable to focus: \(error.localizedDescription)")
                }
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .configurationFailed("Back camera is unavailable")
            }
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                currentDevice = device
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.error = .configurationFailed("Cannot add camera input")
                }
                session.commitConfiguration()
                return
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = .configurationFailed("Camera configuration failed: \(error.localizedDescription)")
            }
            session.commitConfiguration()
            return
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .configurationFailed("Cannot add photo output")
            }
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            DispatchQueue.main.async { [weak self] in
                self?.error = .captureFailed("Capture failed: \(error.localizedDescription)")
            }
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            DispatchQueue.main.async { [weak self] in
                self?.error = .captureFailed("Unable to read captured photo data")
            }
            return
        }

        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: url)
            DispatchQueue.main.async { [weak self] in
                self?.lastCapturedImageURL = url
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = .captureFailed("Saving photo failed: \(error.localizedDescription)")
            }
        }
    }
}
