import Foundation

public struct InferenceBenchmark: Equatable {
    private var samples: [Double] = []
    private let maxSamples = 20

    public init(samples: [Double] = []) {
        self.samples = Array(samples.suffix(maxSamples))
    }

    public var lastRunMilliseconds: Double? { samples.last }
    public var averageMilliseconds: Double? {
        guard !samples.isEmpty else { return nil }
        let total = samples.reduce(0, +)
        return total / Double(samples.count)
    }

    public var sampleCount: Int { samples.count }

    public mutating func record(durationMilliseconds: Double) {
        samples.append(durationMilliseconds)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
    }

    public var isStable: Bool {
        guard samples.count >= 3, let average = averageMilliseconds, average > 0 else { return false }
        guard let min = samples.min(), let max = samples.max() else { return false }
        let spread = (max - min) / average
        return spread < 0.25
    }

    public func formattedSummary() -> String {
        guard let average = averageMilliseconds else { return "No benchmark yet" }
        let stability = isStable ? "Stable" : "Warming up"
        if let last = lastRunMilliseconds {
            return String(format: "Avg %.1f ms · Last %.1f ms · %@", average, last, stability)
        }
        return String(format: "Avg %.1f ms · %@", average, stability)
    }
}
