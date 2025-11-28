import CoreML
import Foundation
import Vision
import UIKit

public protocol OnDeviceInferenceServiceProtocol {
    func prepareModel() async throws
    func runInference(on data: Data) async throws -> InferenceResult
}

public struct InferenceResult: Sendable, Equatable {
    public let summary: String
    public let confidence: Double
    public let metadata: [String: String]

    public init(summary: String, confidence: Double, metadata: [String: String] = [:]) {
        self.summary = summary
        self.confidence = confidence
        self.metadata = metadata
    }
}

public enum OnDeviceInferenceError: LocalizedError {
    case modelNotFound
    case modelNotPrepared
    case preprocessingFailed(String)
    case inferenceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Compiled CoreML model not found in bundle."
        case .modelNotPrepared:
            return "Model not prepared. Call prepareModel() before running inference."
        case .preprocessingFailed(let reason):
            return "Preprocessing failed: \(reason)"
        case .inferenceFailed(let reason):
            return "Inference failed: \(reason)"
        }
    }
}

public final class OnDeviceInferenceService: OnDeviceInferenceServiceProtocol {
    private let modelName: String
    private let labelMapper: LabelMapper
    private let preprocessor = ImagePreprocessor()

    private var vnModel: VNCoreMLModel?
    private var targetImageSize: CGSize?

    public init(modelName: String = "Model", labelMapper: LabelMapper = LabelMapper()) {
        self.modelName = modelName
        self.labelMapper = labelMapper
    }

    public func prepareModel() async throws {
        if vnModel != nil { return }

        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw OnDeviceInferenceError.modelNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let configuration = MLModelConfiguration()
                    configuration.computeUnits = .cpuAndGPU
                    let mlModel = try MLModel(contentsOf: modelURL, configuration: configuration)
                    let vnModel = try VNCoreMLModel(for: mlModel)
                    self.vnModel = vnModel
                    self.targetImageSize = Self.deriveInputSize(from: mlModel)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: OnDeviceInferenceError.inferenceFailed(error.localizedDescription))
                }
            }
        }
    }

    public func runInference(on data: Data) async throws -> InferenceResult {
        guard let vnModel else { throw OnDeviceInferenceError.modelNotPrepared }
        guard let targetImageSize else { throw OnDeviceInferenceError.modelNotPrepared }

        let pixelBuffer: CVPixelBuffer
        do {
            pixelBuffer = try preprocessor.pixelBuffer(from: data, targetSize: targetImageSize)
        } catch {
            throw OnDeviceInferenceError.preprocessingFailed(error.localizedDescription)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error {
                    continuation.resume(throwing: OnDeviceInferenceError.inferenceFailed(error.localizedDescription))
                    return
                }

                do {
                    let result = try Self.handleResults(request.results, mapper: self.labelMapper)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OnDeviceInferenceError.inferenceFailed(error.localizedDescription))
            }
        }
    }

    private static func deriveInputSize(from model: MLModel) -> CGSize {
        if let description = model.modelDescription.inputDescriptionsByName.first?.value,
           let constraint = description.imageConstraint {
            return CGSize(width: constraint.pixelsWide, height: constraint.pixelsHigh)
        }

        return CGSize(width: 224, height: 224)
    }

    private static func handleResults(_ results: [Any]?, mapper: LabelMapper) throws -> InferenceResult {
        if let classifications = results as? [VNClassificationObservation], let top = classifications.first {
            let mappedIndex = Int(top.identifier) ?? -1
            let mappedLabel = mappedIndex >= 0 ? mapper.label(for: mappedIndex) : top.identifier
            let summary = mappedLabel.isEmpty ? top.identifier : mappedLabel
            return InferenceResult(
                summary: summary,
                confidence: Double(top.confidence),
                metadata: [
                    "rawLabel": top.identifier,
                    "mappedLabel": mappedLabel
                ]
            )
        }

        if let feature = results?.first as? VNCoreMLFeatureValueObservation,
           let array = feature.featureValue.multiArrayValue {
            let (index, confidence) = array.argmax()
            let label = mapper.label(for: index)
            return InferenceResult(
                summary: label,
                confidence: confidence,
                metadata: ["classIndex": "\(index)"]
            )
        }

        throw OnDeviceInferenceError.inferenceFailed("Unexpected model output")
    }
}

public final class MockOnDeviceInferenceService: OnDeviceInferenceServiceProtocol {
    public init() {}

    public func prepareModel() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    public func runInference(on data: Data) async throws -> InferenceResult {
        let hashed = abs(data.hashValue % 3)
        return InferenceResult(
            summary: ["healthy", "disease", "unknown"][hashed],
            confidence: 0.8,
            metadata: ["source": "mock"]
        )
    }
}

private extension MLMultiArray {
    func argmax() -> (index: Int, confidence: Double) {
        var bestIndex = 0
        var bestValue = Double(truncating: self[0])

        for i in 1..<count {
            let value = Double(truncating: self[i])
            if value > bestValue {
                bestValue = value
                bestIndex = i
            }
        }

        return (bestIndex, bestValue)
    }
}
