import Foundation
import Shared

final class StubInferenceRepository: InferenceRepositoryProtocol {
    var shouldThrowOnPrepare = false
    var runInferenceHandler: ((Data) throws -> InferenceResult)?
    var storedEntries: [HistoryEntry]
    var benchmarkValue: InferenceBenchmark

    init(
        storedEntries: [HistoryEntry] = [],
        benchmarkValue: InferenceBenchmark = InferenceBenchmark(),
        runInferenceHandler: ((Data) throws -> InferenceResult)? = nil
    ) {
        self.storedEntries = storedEntries
        self.benchmarkValue = benchmarkValue
        self.runInferenceHandler = runInferenceHandler
    }

    func prepareModel() async throws {
        if shouldThrowOnPrepare {
            throw NSError(domain: "prepare", code: -1)
        }
    }

    func runInference(on data: Data, saveToHistory: Bool) async throws -> InferenceResult {
        if let handler = runInferenceHandler {
            let result = try handler(data)
            if saveToHistory {
                _ = try? saveHistory(result, isFavorite: false)
            }
            return result
        }
        return InferenceResult(summary: "mock", confidence: 0.9, metadata: [:], timingMilliseconds: 10)
    }

    func benchmarkMetrics() -> InferenceBenchmark {
        benchmarkValue
    }

    func fetchHistory() throws -> [HistoryEntry] {
        storedEntries
    }

    @discardableResult
    func saveHistory(_ result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry {
        let entry = HistoryEntry(id: UUID(), timestamp: Date(), result: result, isFavorite: isFavorite)
        storedEntries.insert(entry, at: 0)
        return entry
    }

    func updateFavorite(for id: UUID, isFavorite: Bool) throws {
        guard let index = storedEntries.firstIndex(where: { $0.id == id }) else { return }
        let entry = storedEntries[index]
        storedEntries[index] = HistoryEntry(
            id: entry.id,
            timestamp: entry.timestamp,
            result: entry.result,
            isFavorite: isFavorite
        )
    }
}

@MainActor
final class StubPermissionsManager: PermissionsManager {
    var nextCameraStatus: PermissionState?
    var nextPhotoLibraryStatus: PermissionState?

    init(
        cameraStatus: PermissionState = .authorized,
        photoLibraryStatus: PermissionState = .authorized
    ) {
        super.init(cameraStatus: cameraStatus, photoLibraryStatus: photoLibraryStatus)
    }

    override func refreshStatuses() {
        if let camera = nextCameraStatus {
            cameraStatus = camera
        }
        if let photo = nextPhotoLibraryStatus {
            photoLibraryStatus = photo
        }
    }

    override func requestAccess(for type: PermissionType) async {
        switch type {
        case .camera:
            cameraStatus = nextCameraStatus ?? cameraStatus
        case .photoLibrary:
            photoLibraryStatus = nextPhotoLibraryStatus ?? photoLibraryStatus
        }
    }

    override func requestCameraAccess() async {
        cameraStatus = nextCameraStatus ?? cameraStatus
    }

    override func requestPhotoLibraryAccess() async {
        photoLibraryStatus = nextPhotoLibraryStatus ?? photoLibraryStatus
    }
}
