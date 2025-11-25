import Foundation

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

    public init(settings: InferenceSettings = .init()) {
        self.settings = settings
    }
}
