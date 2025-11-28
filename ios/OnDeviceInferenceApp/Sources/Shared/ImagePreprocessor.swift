import CoreGraphics
import Foundation
import UIKit

public struct ImagePreprocessor {
    public enum PreprocessError: LocalizedError {
        case invalidImageData
        case bufferCreationFailed

        public var errorDescription: String? {
            switch self {
            case .invalidImageData:
                return "Unable to decode image data"
            case .bufferCreationFailed:
                return "Failed to create pixel buffer"
            }
        }
    }

    public init() {}

    public func pixelBuffer(from data: Data, targetSize: CGSize, normalize: Bool = true) throws -> CVPixelBuffer {
        guard let image = UIImage(data: data)?.fixedOrientation() else {
            throw PreprocessError.invalidImageData
        }

        let squared = image.centerCroppedSquare()
        let resized = squared.resized(to: targetSize)

        guard let buffer = resized.pixelBuffer(normalize: normalize) else {
            throw PreprocessError.bufferCreationFailed
        }

        return buffer
    }
}

private extension UIImage {
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }

    func centerCroppedSquare() -> UIImage {
        let minLength = min(size.width, size.height)
        let origin = CGPoint(
            x: (size.width - minLength) / 2.0,
            y: (size.height - minLength) / 2.0
        )
        let cropRect = CGRect(origin: origin, size: CGSize(width: minLength, height: minLength))
        guard let cgImage = cgImage?.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    func resized(to targetSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func pixelBuffer(normalize: Bool) -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var optionalBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &optionalBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = optionalBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else {
            return nil
        }

        guard let cgImage = cgImage else { return nil }
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        if normalize {
            normalizeBuffer(pixelBuffer, width: width, height: height)
        }

        return pixelBuffer
    }

    private func normalizeBuffer(_ buffer: CVPixelBuffer, width: Int, height: Int) {
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        let bufferPointer = baseAddress?.assumingMemoryBound(to: UInt8.self)
        let pixelCount = height * bytesPerRow
        guard let pointer = bufferPointer else { return }

        for offset in stride(from: 0, to: pixelCount, by: 4) {
            pointer[offset] = normalizeChannel(pointer[offset])
            pointer[offset + 1] = normalizeChannel(pointer[offset + 1])
            pointer[offset + 2] = normalizeChannel(pointer[offset + 2])
        }
    }

    private func normalizeChannel(_ value: UInt8) -> UInt8 {
        let normalized = (Float(value) / 255.0 - 0.5) * 2.0
        let clamped = max(-1.0, min(1.0, normalized))
        return UInt8((clamped + 1) * 127.5)
    }
}
