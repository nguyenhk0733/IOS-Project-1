import Foundation

public struct LabelMapper {

    private let labels: [String]

    // MARK: - Designated initializer (NO default Bundle.module)
    public init(bundle: Bundle, resourceName: String = "labels") {
        if let url = bundle.url(forResource: resourceName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.labels = decoded
        } else {
            self.labels = []
        }
    }

    // MARK: - Convenience initializer for app runtime
    public init(resourceName: String = "labels") {
        self.init(bundle: Bundle.module, resourceName: resourceName)
    }

    // MARK: - API
    public func label(for index: Int) -> String {
        guard labels.indices.contains(index) else {
            return "Class_\(index)"
        }
        return labels[index]
    }
}

