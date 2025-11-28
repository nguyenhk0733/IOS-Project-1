import Foundation

public struct LabelMapper {
    private let labels: [String]

    public init(bundle: Bundle = .module, resourceName: String = "labels") {
        let url = bundle.url(forResource: resourceName, withExtension: "json")
        if let url, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            labels = decoded
        } else {
            labels = []
        }
    }

    public func label(for index: Int) -> String {
        guard labels.indices.contains(index) else {
            return "Class_\(index)"
        }
        return labels[index]
    }
}
