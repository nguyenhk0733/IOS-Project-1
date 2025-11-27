import AVFoundation
import SwiftUI

public struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var manager: CameraSessionManager

    public init(manager: CameraSessionManager) {
        self.manager = manager
    }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = manager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapRecognizer)
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(manager: manager)
    }

    public final class Coordinator: NSObject {
        private let manager: CameraSessionManager

        init(manager: CameraSessionManager) {
            self.manager = manager
        }

        @objc
        func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? PreviewView else { return }
            let tapPoint = gesture.location(in: view)
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: tapPoint)
            manager.focus(at: devicePoint)
        }
    }
}

public final class PreviewView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
