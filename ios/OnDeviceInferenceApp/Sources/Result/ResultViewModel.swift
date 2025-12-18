import Foundation
import Shared

public final class ResultViewModel: ObservableObject {
    @Published public private(set) var result: InferenceResult? = nil
    @Published public private(set) var isRunning = false
    @Published public private(set) var errorMessage: String? = nil

    private let repository: InferenceRepositoryProtocol

    public init(repository: InferenceRepositoryProtocol = MockInferenceRepository()) {
        self.repository = repository
    }

    @MainActor
    public func runInference(with data: Data) async {
        isRunning = true
        errorMessage = nil
        do {
            result = try await repository.runInference(on: data)
        } catch {
            errorMessage = error.localizedDescription
        }
        isRunning = false
    }
}
