import CoreML
import Foundation
import Vision
import UIKit

// MARK: - Protocol

public protocol OnDeviceInferenceServiceProtocol {
    func prepareModel() async throws
    func runInference(on data: Data) async throws -> InferenceResult
    func benchmarkMetrics() -> InferenceBenchmark
}

// MARK: - Result

public struct InferenceResult: Sendable, Equatable {
    public let summary: String
    public let confidence: Double
    public let metadata: [String: String]
    public let timingMilliseconds: Double?

    public init(
        summary: String,
        confidence: Double,
        metadata: [String: String] = [:],
        timingMilliseconds: Double? = nil
    ) {
        self.summary = summary
        self.confidence = confidence
        self.metadata = metadata
        self.timingMilliseconds = timingMilliseconds
    }
}

// MARK: - Errors

public enum OnDeviceInferenceError: LocalizedError, Equatable {
    case modelNotFound
    case modelNotPrepared
    case preprocessingFailed(String)
    case inferenceFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return L10n.string("model_not_found")
        case .modelNotPrepared:
            return L10n.string("model_not_prepared")
        case .preprocessingFailed(let reason):
            return L10n.formatted("preprocessing_failed_format", reason)
        case .inferenceFailed(let reason):
            return L10n.formatted("inference_failed_format", reason)
        }
    }

    // ✅ Equatable synthesis is OK, but we keep it explicit-safe for String associated values.
    public static func == (lhs: OnDeviceInferenceError, rhs: OnDeviceInferenceError) -> Bool {
        switch (lhs, rhs) {
        case (.modelNotFound, .modelNotFound),
             (.modelNotPrepared, .modelNotPrepared):
            return true

        case let (.preprocessingFailed(a), .preprocessingFailed(b)):
            return a == b

        case let (.inferenceFailed(a), .inferenceFailed(b)):
            return a == b

        default:
            return false
        }
    }
}

// MARK: - Service

public final class OnDeviceInferenceService: OnDeviceInferenceServiceProtocol {

    private let modelName: String
    private let labelMapper: LabelMapper
    private let preprocessor: ImagePreprocessor
    private let modelBundle: Bundle

    private var benchmark = InferenceBenchmark()
    private var vnModel: VNCoreMLModel?
    private var targetImageSize: CGSize?

    /// ✅ `modelBundle` injected for testability (Bundle.main by default).
    /// ✅ `labelMapper` uses your fixed LabelMapper() (no Bundle.module default-arg issue).
    public init(
        modelName: String = "Model",
        modelBundle: Bundle = .main,
        labelMapper: LabelMapper = LabelMapper(),
        preprocessor: ImagePreprocessor = ImagePreprocessor()
    ) {
        self.modelName = modelName
        self.modelBundle = modelBundle
        self.labelMapper = labelMapper
        self.preprocessor = preprocessor
    }

    public func prepareModel() async throws {
        if vnModel != nil { return }

        guard let modelURL = modelBundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw OnDeviceInferenceError.modelNotFound
        }

        try await withCheckedThrowingContinuation { continuation in
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
                    continuation.resume(
                        throwing: OnDeviceInferenceError.inferenceFailed(error.localizedDescription)
                    )
                }
            }
        }
    }

    public func runInference(on data: Data) async throws -> InferenceResult {
        guard let vnModel else { throw OnDeviceInferenceError.modelNotPrepared }
        guard let targetImageSize else { throw OnDeviceInferenceError.modelNotPrepared }

        let start = CFAbsoluteTimeGetCurrent()

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
                    let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
                    self.benchmark.record(durationMilliseconds: elapsedMs)

                    let result = try Self.handleResults(
                        request.results,
                        mapper: self.labelMapper,
                        timingMilliseconds: elapsedMs
                    )

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

    public func benchmarkMetrics() -> InferenceBenchmark {
        benchmark
    }

    // MARK: - Helpers

    private static func deriveInputSize(from model: MLModel) -> CGSize {
        if let description = model.modelDescription.inputDescriptionsByName.first?.value,
           let constraint = description.imageConstraint {
            return CGSize(width: constraint.pixelsWide, height: constraint.pixelsHigh)
        }

        return CGSize(width: 224, height: 224)
    }

    private static func handleResults(
        _ results: [Any]?,
        mapper: LabelMapper,
        timingMilliseconds: Double?
    ) throws -> InferenceResult {

        if let classifications = results as? [VNClassificationObservation], let top = classifications.first {
            // top.identifier might be "0", "1", ... or a string label depending on the model
            let mappedIndex = Int(top.identifier) ?? -1
            let mappedLabel = mappedIndex >= 0 ? mapper.label(for: mappedIndex) : top.identifier
            let summary = mappedLabel.isEmpty ? top.identifier : mappedLabel

            return InferenceResult(
                summary: summary,
                confidence: Double(top.confidence),
                metadata: [
                    "rawLabel": top.identifier,
                    "mappedLabel": mappedLabel,
                    "inferenceTimeMs": String(format: "%.1f", timingMilliseconds ?? 0)
                ],
                timingMilliseconds: timingMilliseconds
            )
        }

        if let feature = results?.first as? VNCoreMLFeatureValueObservation,
           let array = feature.featureValue.multiArrayValue {
            let (index, confidence) = array.argmax()
            let label = mapper.label(for: index)

            return InferenceResult(
                summary: label,
                confidence: confidence,
                metadata: [
                    "classIndex": "\(index)",
                    "inferenceTimeMs": String(format: "%.1f", timingMilliseconds ?? 0)
                ],
                timingMilliseconds: timingMilliseconds
            )
        }

        throw OnDeviceInferenceError.inferenceFailed(L10n.string("unexpected_model_output"))
    }
}

// MARK: - Mock Service

public final class MockOnDeviceInferenceService: OnDeviceInferenceServiceProtocol {
    private var benchmark = InferenceBenchmark()

    public init() {}

    public func prepareModel() async throws {
        try await Task.sleep(nanoseconds: 50_000_000)
    }

    public func runInference(on data: Data) async throws -> InferenceResult {
        let start = CFAbsoluteTimeGetCurrent()

        let hashed = abs(data.hashValue % 3)
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000

        benchmark.record(durationMilliseconds: elapsedMs)

        return InferenceResult(
            summary: ["healthy", "disease", "unknown"][hashed],
            confidence: 0.8,
            metadata: [
                "source": "mock",
                "inferenceTimeMs": String(format: "%.1f", elapsedMs)
            ],
            timingMilliseconds: elapsedMs
        )
    }

    public func benchmarkMetrics() -> InferenceBenchmark {
        benchmark
    }
}

// MARK: - MLMultiArray argmax

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

