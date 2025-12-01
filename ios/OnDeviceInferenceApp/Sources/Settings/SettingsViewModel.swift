import Foundation
import Shared

public enum TextFormattingStyle: String, CaseIterable, Identifiable {
    case asEntered
    case uppercase
    case titleCase

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .asEntered: return "Original"
        case .uppercase: return "Uppercase"
        case .titleCase: return "Title Case"
        }
    }

    public func format(_ text: String) -> String {
        switch self {
        case .asEntered:
            return text
        case .uppercase:
            return text.uppercased()
        case .titleCase:
            return text.capitalized
        }
    }
}

public struct TopUserPreference: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let capability: String

    public init(id: UUID = UUID(), name: String, capability: String) {
        self.id = id
        self.name = name
        self.capability = capability
    }

    public func formattedName(using style: TextFormattingStyle) -> String {
        style.format(name)
    }

    public static var featured: [TopUserPreference] {
        [
            TopUserPreference(name: "Radiologist", capability: "Reviews scans with high accuracy"),
            TopUserPreference(name: "Clinician", capability: "Quickly triages bedside captures"),
            TopUserPreference(name: "Researcher", capability: "Explores edge cases and anomalies")
        ]
    }
}

public struct InferenceSettings: Equatable {
    public var enableTelemetry: Bool
    public var preferredComputeUnit: ComputeUnit
    public var autoSaveHistory: Bool

    public init(enableTelemetry: Bool = false, preferredComputeUnit: ComputeUnit = .auto, autoSaveHistory: Bool = true) {
        self.enableTelemetry = enableTelemetry
        self.preferredComputeUnit = preferredComputeUnit
        self.autoSaveHistory = autoSaveHistory
    }
}

public enum ComputeUnit: String, CaseIterable, Identifiable {
    case auto
    case cpuOnly
    case neuralEngine
    case gpu

    public var id: String { rawValue }
    public var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .cpuOnly: return "CPU"
        case .neuralEngine: return "Neural Engine"
        case .gpu: return "GPU"
        }
    }
}

public final class SettingsViewModel: ObservableObject {
    @Published public var settings: InferenceSettings
    @Published public var formattingStyle: TextFormattingStyle
    @Published public private(set) var topUsers: [TopUserPreference]
    @Published public private(set) var benchmark: InferenceBenchmark
    @Published public private(set) var benchmarkError: String?

    private let inferenceService: OnDeviceInferenceServiceProtocol?
    private let benchmarkPayload = Data("benchmark-probe".utf8)

    public init(
        settings: InferenceSettings = .init(),
        formattingStyle: TextFormattingStyle = .titleCase,
        topUsers: [TopUserPreference] = TopUserPreference.featured,
        inferenceService: OnDeviceInferenceServiceProtocol? = nil
    ) {
        self.settings = settings
        self.formattingStyle = formattingStyle
        self.topUsers = topUsers
        self.inferenceService = inferenceService
        self.benchmark = inferenceService?.benchmarkMetrics() ?? InferenceBenchmark()
    }

    public func refreshBenchmark() {
        benchmark = inferenceService?.benchmarkMetrics() ?? benchmark
    }

    @MainActor
    public func runBenchmarkProbe() async {
        guard let inferenceService else {
            benchmarkError = "Inference service unavailable"
            return
        }

        benchmarkError = nil

        do {
            try await inferenceService.prepareModel()
            _ = try await inferenceService.runInference(on: benchmarkPayload)
            benchmark = inferenceService.benchmarkMetrics()
        } catch {
            benchmarkError = error.localizedDescription
        }
    }
}
