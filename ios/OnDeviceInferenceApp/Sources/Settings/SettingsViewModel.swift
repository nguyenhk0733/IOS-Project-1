import Foundation
import Shared

public enum TextFormattingStyle: String, CaseIterable, Identifiable {
    case asEntered
    case uppercase
    case titleCase

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .asEntered: return L10n.string("formatting_original")
        case .uppercase: return L10n.string("formatting_uppercase")
        case .titleCase: return L10n.string("formatting_titlecase")
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

public enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case vietnamese

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system: return L10n.string("language_system")
        case .english: return L10n.string("language_english")
        case .vietnamese: return L10n.string("language_vietnamese")
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
            TopUserPreference(
                name: L10n.string("top_user_radiologist"),
                capability: L10n.string("top_user_radiologist_capability")
            ),
            TopUserPreference(
                name: L10n.string("top_user_clinician"),
                capability: L10n.string("top_user_clinician_capability")
            ),
            TopUserPreference(
                name: L10n.string("top_user_researcher"),
                capability: L10n.string("top_user_researcher_capability")
            )
        ]
    }
}

public struct InferenceSettings: Equatable {
    public var enableTelemetry: Bool
    public var preferredComputeUnit: ComputeUnit
    public var autoSaveHistory: Bool
    public var enableHaptics: Bool
    public var language: AppLanguage
    public var privacyModeEnabled: Bool

    public init(
        enableTelemetry: Bool = false,
        preferredComputeUnit: ComputeUnit = .auto,
        autoSaveHistory: Bool = true,
        enableHaptics: Bool = true,
        language: AppLanguage = .system,
        privacyModeEnabled: Bool = false
    ) {
        self.enableTelemetry = enableTelemetry
        self.preferredComputeUnit = preferredComputeUnit
        self.autoSaveHistory = autoSaveHistory
        self.enableHaptics = enableHaptics
        self.language = language
        self.privacyModeEnabled = privacyModeEnabled
    }
}

public struct ModelInfo: Equatable {
    public var bundledName: String
    public var bundledVersion: String
    public var remoteEndpoint: URL
    public var remoteStatus: String

    public init(
        bundledName: String = "Model",
        bundledVersion: String = "1.0",
        remoteEndpoint: URL = URL(string: "https://plant-disease-api-qm2p.onrender.com")!,
        remoteStatus: String = L10n.string("remote_update_placeholder")
    ) {
        self.bundledName = bundledName
        self.bundledVersion = bundledVersion
        self.remoteEndpoint = remoteEndpoint
        self.remoteStatus = remoteStatus
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
        case .auto: return L10n.string("compute_auto")
        case .cpuOnly: return L10n.string("compute_cpu")
        case .neuralEngine: return L10n.string("compute_neural")
        case .gpu: return L10n.string("compute_gpu")
        }
    }
}

public final class SettingsViewModel: ObservableObject {
    @Published public var settings: InferenceSettings
    @Published public var formattingStyle: TextFormattingStyle
    @Published public private(set) var topUsers: [TopUserPreference]
    @Published public private(set) var benchmark: InferenceBenchmark
    @Published public private(set) var benchmarkError: String?
    @Published public private(set) var modelInfo: ModelInfo

    private let repository: InferenceRepositoryProtocol?
    private let benchmarkPayload = Data("benchmark-probe".utf8)

    public init(
        settings: InferenceSettings = .init(),
        formattingStyle: TextFormattingStyle = .titleCase,
        topUsers: [TopUserPreference] = TopUserPreference.featured,
        repository: InferenceRepositoryProtocol? = nil,
        modelInfo: ModelInfo = ModelInfo()
    ) {
        self.settings = settings
        self.formattingStyle = formattingStyle
        self.topUsers = topUsers
        self.repository = repository
        self.modelInfo = modelInfo
        self.benchmark = repository?.benchmarkMetrics() ?? InferenceBenchmark()
    }

    public func refreshBenchmark() {
        benchmark = repository?.benchmarkMetrics() ?? benchmark
    }

    @MainActor
    public func runBenchmarkProbe() async {
        guard let repository else {
            benchmarkError = L10n.string("inference_service_unavailable")
            return
        }

        benchmarkError = nil

        do {
            try await repository.prepareModel()
            _ = try await repository.runInference(on: benchmarkPayload)
            benchmark = repository.benchmarkMetrics()
        } catch {
            benchmarkError = error.localizedDescription
        }
    }
}
