import CoreData
import Foundation
import Shared

public final class HistoryStore: HistoryStoring {

    // MARK: - Singleton
    public static let shared = HistoryStore()

    // MARK: - Core Data
    private let container: NSPersistentContainer

    // MARK: - Initializers

    /// Default initializer (used by app)
    public init() {
        self.container = HistoryStore.makeContainer()
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Designated initializer (used by tests / dependency injection)
    public init(container: NSPersistentContainer) {
        self.container = container
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Fetch

    public func fetchEntries() throws -> [HistoryEntry] {
        let request: NSFetchRequest<HistoryItem> = HistoryItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(HistoryItem.timestamp),
                ascending: false
            )
        ]

        let items = try container.viewContext.fetch(request)
        return items.compactMap(Self.mapToEntry)
    }

    // MARK: - Save

    @discardableResult
    public func save(
        result: InferenceResult,
        isFavorite: Bool
    ) throws -> HistoryEntry {

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

    // MARK: - Update

    public func updateFavorite(
        for id: UUID,
        isFavorite: Bool
    ) throws {

        let request: NSFetchRequest<HistoryItem> = HistoryItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@",
            #keyPath(HistoryItem.id),
            id as CVarArg
        )
        request.fetchLimit = 1

        guard let item = try container.viewContext.fetch(request).first else {
            return
        }

        item.isFavorite = isFavorite
        try container.viewContext.save()
    }

    // MARK: - Core Data Container

    /// Internal factory for Core Data container
    static func makeContainer() -> NSPersistentContainer {

        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "HistoryItem"
        entity.managedObjectClassName = NSStringFromClass(HistoryItem.self)

        // id
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = true

        // timestamp
        let timestampAttribute = NSAttributeDescription()
        timestampAttribute.name = "timestamp"
        timestampAttribute.attributeType = .dateAttributeType
        timestampAttribute.isOptional = true

        // summary
        let summaryAttribute = NSAttributeDescription()
        summaryAttribute.name = "summary"
        summaryAttribute.attributeType = .stringAttributeType
        summaryAttribute.isOptional = false
        summaryAttribute.defaultValue = ""

        // confidence
        let confidenceAttribute = NSAttributeDescription()
        confidenceAttribute.name = "confidence"
        confidenceAttribute.attributeType = .doubleAttributeType
        confidenceAttribute.isOptional = false
        confidenceAttribute.defaultValue = 0.0

        // metadata
        let metadataAttribute = NSAttributeDescription()
        metadataAttribute.name = "metadataData"
        metadataAttribute.attributeType = .binaryDataAttributeType
        metadataAttribute.isOptional = true

        // timing
        let timingAttribute = NSAttributeDescription()
        timingAttribute.name = "timingMilliseconds"
        timingAttribute.attributeType = .doubleAttributeType
        timingAttribute.isOptional = true

        // favorite
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

        let container = NSPersistentContainer(
            name: "HistoryModel",
            managedObjectModel: model
        )

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error.localizedDescription)")
            }
        }

        return container
    }

    // MARK: - Mapping

    private static func mapToEntry(
        from item: HistoryItem
    ) -> HistoryEntry? {

        guard let id = item.id,
              let timestamp = item.timestamp else {
            return nil
        }

        return HistoryEntry(
            id: id,
            timestamp: timestamp,
            result: mapToResult(from: item),
            isFavorite: item.isFavorite
        )
    }

    private static func mapToResult(
        from item: HistoryItem
    ) -> InferenceResult {

        let metadata: [String: String]

        if let data = item.metadataData,
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
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

// MARK: - Core Data Entity

@objc(HistoryItem)
final class HistoryItem: NSManagedObject {

    @NSManaged var id: UUID?
    @NSManaged var timestamp: Date?
    @NSManaged var summary: String?
    @NSManaged var confidence: Double
    @NSManaged var metadataData: Data?
    @NSManaged var timingMilliseconds: Double
    @NSManaged var isFavorite: Bool

    @nonobjc
    class func fetchRequest() -> NSFetchRequest<HistoryItem> {
        NSFetchRequest<HistoryItem>(entityName: "HistoryItem")
    }
}

