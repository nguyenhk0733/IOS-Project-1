import CoreData
import Foundation
import Shared

public final class HistoryStore: HistoryStoring {
    public static let shared = HistoryStore()

    private let container: NSPersistentContainer

    public init(container: NSPersistentContainer = HistoryStore.makeContainer()) {
        self.container = container
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public func fetchEntries() throws -> [HistoryEntry] {
        let request: NSFetchRequest<HistoryItem> = HistoryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(HistoryItem.timestamp), ascending: false)]
        let items = try container.viewContext.fetch(request)
        return items.compactMap(Self.mapToEntry)
    }

    @discardableResult
    public func save(result: InferenceResult, isFavorite: Bool) throws -> HistoryEntry {
        let context = container.viewContext
        let item = HistoryItem(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.summary = result.summary
        item.confidence = result.confidence
        item.isFavorite = isFavorite
        item.timingMilliseconds = result.timingMilliseconds ?? 0
        item.metadataData = try? JSONEncoder().encode(result.metadata)

        try context.save()

        return HistoryEntry(
            id: item.id ?? UUID(),
            timestamp: item.timestamp ?? Date(),
            result: Self.mapToResult(from: item),
            isFavorite: item.isFavorite
        )
    }

    public func updateFavorite(for id: UUID, isFavorite: Bool) throws {
        let request: NSFetchRequest<HistoryItem> = HistoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(HistoryItem.id), id as CVarArg)
        request.fetchLimit = 1

        guard let item = try container.viewContext.fetch(request).first else { return }
        item.isFavorite = isFavorite
        try container.viewContext.save()
    }

    private static func makeContainer() -> NSPersistentContainer {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "HistoryItem"
        entity.managedObjectClassName = NSStringFromClass(HistoryItem.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = true

        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = true

        let summaryAttribute = NSAttributeDescription()
        summaryAttribute.name = "summary"
        summaryAttribute.attributeType = .stringAttributeType
        summaryAttribute.isOptional = false

        let confidenceAttribute = NSAttributeDescription()
        confidenceAttribute.name = "confidence"
        confidenceAttribute.attributeType = .doubleAttributeType
        confidenceAttribute.isOptional = false

        let metadataAttribute = NSAttributeDescription()
        metadataAttribute.name = "metadataData"
        metadataAttribute.attributeType = .binaryDataAttributeType
        metadataAttribute.isOptional = true

        let timingAttribute = NSAttributeDescription()
        timingAttribute.name = "timingMilliseconds"
        timingAttribute.attributeType = .doubleAttributeType
        timingAttribute.isOptional = true

        let favoriteAttribute = NSAttributeDescription()
        favoriteAttribute.name = "isFavorite"
        favoriteAttribute.attributeType = .booleanAttributeType
        favoriteAttribute.isOptional = false
        favoriteAttribute.defaultValue = false

        entity.properties = [
            idAttribute,
            timestampAttribute,
            summaryAttribute,
            confidenceAttribute,
            metadataAttribute,
            timingAttribute,
            favoriteAttribute
        ]

        model.entities = [entity]

        let container = NSPersistentContainer(name: "HistoryModel", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error.localizedDescription)")
            }
        }

        return container
    }

    private static func mapToEntry(from item: HistoryItem) -> HistoryEntry? {
        guard let id = item.id, let timestamp = item.timestamp else { return nil }
        return HistoryEntry(
            id: id,
            timestamp: timestamp,
            result: mapToResult(from: item),
            isFavorite: item.isFavorite
        )
    }

    private static func mapToResult(from item: HistoryItem) -> InferenceResult {
        let metadata: [String: String]
        if let metadataData = item.metadataData,
           let decoded = try? JSONDecoder().decode([String: String].self, from: metadataData) {
            metadata = decoded
        } else {
            metadata = [:]
        }

        return InferenceResult(
            summary: item.summary ?? "",
            confidence: item.confidence,
            metadata: metadata,
            timingMilliseconds: item.timingMilliseconds == 0 ? nil : item.timingMilliseconds
        )
    }
}

@objc(HistoryItem)
final class HistoryItem: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var timestamp: Date?
    @NSManaged var summary: String?
    @NSManaged var confidence: Double
    @NSManaged var metadataData: Data?
    @NSManaged var timingMilliseconds: Double
    @NSManaged var isFavorite: Bool

    @nonobjc class func fetchRequest() -> NSFetchRequest<HistoryItem> {
        NSFetchRequest<HistoryItem>(entityName: "HistoryItem")
    }
}
