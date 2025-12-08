// File: Tests/ModelIOTests/ModelIOTests.swift
import XCTest
@testable import Shared

final class ModelIOTests: XCTestCase {
    private var inferenceService: OnDeviceInferenceService!
    private let defaultTolerance: Double = 0.05

    override func setUp() async throws {
        inferenceService = OnDeviceInferenceService()
        try await inferenceService.prepareModel()
    }

    override func tearDown() async throws {
        inferenceService = nil
    }

    func testGoldenImagesProduceExpectedOutputs() async throws {
        let samples: [GoldenSample] = [
            .init(fileName: "healthy_leaf.png", expectedLabel: "healthy", expectedConfidence: 0.92, tolerance: 0.05),
            .init(fileName: "rust_leaf.png", expectedLabel: "rust", expectedConfidence: 0.87, tolerance: 0.05),
            .init(fileName: "blight_leaf.png", expectedLabel: "blight", expectedConfidence: nil, tolerance: 0.05)
        ]

        for sample in samples {
            guard let imageData = try loadImageData(named: sample.fileName) else {
                throw XCTSkip("Missing golden image: \(sample.fileName). Add it under Tests/ModelIOTests/TestImages/.")
            }

            let result = try await inferenceService.runInference(on: imageData)
            XCTAssertEqual(result.summary, sample.expectedLabel, "Label mismatch for \(sample.fileName)")

            if let expectedConfidence = sample.expectedConfidence {
                let delta = abs(result.confidence - expectedConfidence)
                XCTAssertLessThanOrEqual(
                    delta,
                    sample.tolerance ?? defaultTolerance,
                    "Confidence for \(sample.fileName) differs by more than tolerance"
                )
            }
        }
    }

    private func loadImageData(named fileName: String) throws -> Data? {
        let components = fileName.split(separator: ".", omittingEmptySubsequences: false)
        let resource: String
        let ext: String?

        if components.count > 1 {
            resource = components.dropLast().joined(separator: ".")
            ext = String(components.last ?? "png")
        } else {
            resource = fileName
            ext = nil
        }

        if let url = Bundle.module.url(forResource: resource, withExtension: ext) {
            return try Data(contentsOf: url)
        }
        return nil
    }
}

private struct GoldenSample {
    let fileName: String
    let expectedLabel: String
    let expectedConfidence: Double?
    let tolerance: Double?
}
