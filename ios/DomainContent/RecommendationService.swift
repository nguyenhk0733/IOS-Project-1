import Foundation

// MARK: - Data Models

public struct RecommendationPayload: Decodable {
    public struct Metadata: Decodable {
        public let source: String
        public let totalLabels: Int
        public let quickReferenceRows: Int

        private enum CodingKeys: String, CodingKey {
            case source
            case totalLabels = "total_labels"
            case quickReferenceRows = "quick_reference_rows"
        }
    }

    public struct GeneralBlocks: Decodable {
        public let defaultHealthy: String
        public let ipm: String
        public let safety: String
        public let resistance: String
        public let fallback: String

        private enum CodingKeys: String, CodingKey {
            case defaultHealthy = "default_healthy"
            case ipm
            case safety
            case resistance
            case fallback
        }
    }

    public struct Recommendation: Decodable, Identifiable {
        public let label: String
        public let title: String?
        public let crop: String?
        public let disease: String?
        public let markdown: String

        public var id: String { label }

        private enum CodingKeys: String, CodingKey {
            case label
            case title
            case crop
            case disease
            case markdown
        }
    }

    public struct QuickRefRow: Decodable, Identifiable {
        public let cropDisease: String
        public let type: String
        public let group: String
        public let actives: String
        public let timing: String
        public let notes: String

        public var id: String { cropDisease }

        private enum CodingKeys: String, CodingKey {
            case cropDisease = "crop_disease"
            case type
            case group
            case actives
            case timing
            case notes
        }
    }

    public let metadata: Metadata
    public let generalBlocks: GeneralBlocks
    public let recommendations: [Recommendation]
    public let quickReference: [QuickRefRow]

    private enum CodingKeys: String, CodingKey {
        case metadata
        case generalBlocks = "general_blocks"
        case recommendations
        case quickReference = "quick_reference"
    }
}

// MARK: - Service

public final class RecommendationService {
    public static let shared = RecommendationService()

    private let decoder = JSONDecoder()
    private let bundle: Bundle
    private(set) var cachedPayload: RecommendationPayload?

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    @discardableResult
    public func load(resource: String = "recommendations_vi", withExtension ext: String = "json") throws -> RecommendationPayload {
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            throw NSError(domain: "RecommendationService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing resource \(resource).\(ext) in bundle \(bundle.bundleIdentifier ?? "main")"
            ])
        }

        let data = try Data(contentsOf: url)
        let payload = try decoder.decode(RecommendationPayload.self, from: data)
        cachedPayload = payload
        return payload
    }

    public var payload: RecommendationPayload? {
        if let cachedPayload { return cachedPayload }
        return try? load()
    }

    public func recommendation(for label: String) -> RecommendationPayload.Recommendation? {
        return payload?.recommendations.first { $0.label == label }
    }
}
