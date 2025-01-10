//
//  CoreDataAssetManager.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Foundation
import Combine
import CoreData

class CoreDataAssetDatabase: NestDatabase {
    private let persistentContainer: NSPersistentContainer
    private var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: Object lifecycle

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer

        installBindings()
    }

    /// Adds a new asset or updates an existing one in the database.
    /// - Parameter asset: The `NEAsset` to be added or updated.
    /// - Throws: An error if saving to the database fails.
    func add(_ asset: NEAsset) async throws {
        try await viewContext.perform { [viewContext] in
            let newAsset = asset.toCoreDataAsset(in: viewContext)
            viewContext.insert(newAsset)
            try viewContext.save()
        }
    }

    func update(_ asset: NEAsset) async throws {
        try await viewContext.perform { [viewContext] in
            guard let coreDataAsset = try self.fetchAsset(byId: asset.id, context: viewContext) else {
                throw NestError.assetNotFound
            }
            // Update the existing record
            coreDataAsset.type = asset.type.stringValue
            coreDataAsset.metadata = asset.metadataJSONString()
            coreDataAsset.fileSize = asset.fileSize.map { Int64($0) } ?? 0
            coreDataAsset.modifiedAt = Date()
            try viewContext.save()
        }
    }

    /// Fetches a CoreData asset entity by its unique identifier.
    /// - Parameter id: The unique identifier of the asset to fetch.
    /// - Returns: The `Asset` entity if found.
    /// - Throws: `NestError.dataNotFound` if the asset does not exist in the database.
    private func fetchAsset(byId id: String, context: NSManagedObjectContext) throws -> Asset? {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first
    }

    func fetch(byId id: String) async throws -> NEAsset? {
        try await persistentContainer.performBackgroundTask { context in
            guard let coreDataAsset = try self.fetchAsset(byId: id, context: context) else {
                return nil
            }
            return coreDataAsset.toNEAsset()
        }
    }

    func delete(byId id: String) async throws {
        try await viewContext.perform { [viewContext] in
            guard let coreDataAsset = try self.fetchAsset(byId: id, context: viewContext) else {
                return
            }
            viewContext.delete(coreDataAsset)
            try viewContext.save()
        }
    }

    func fetch(limit: Int, offset: Int, filters: [QueryFilter], ascending: Bool) async throws -> [NEAsset] {
        let predicate = createCompoundPredicate(from: filters, logicalOperator: .or)
        return try await persistentContainer.performBackgroundTask { context in
            let request: NSFetchRequest<Asset> = Asset.fetchRequest()
            request.fetchLimit = limit
            request.fetchOffset = offset
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: ascending)]
            let assets = try context.fetch(request).map { $0.toNEAsset() }
            return assets
        }
    }

    func deleteAll() async throws {
        try await persistentContainer.performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Asset")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
            try context.save()
        }
    }

    private func createCompoundPredicate(
        from filters: [QueryFilter]?,
        logicalOperator: NSCompoundPredicate.LogicalType
    ) -> NSPredicate? {
        guard let filters, !filters.isEmpty else { return nil }

        let predicates = filters.map { filter -> NSPredicate in
            switch filter.comparison {
            case .equal:
                return NSPredicate(format: "%K == %@", filter.field, filter.value as! CVarArg)
            case .lessThan:
                return NSPredicate(format: "%K < %@", filter.field, filter.value as! CVarArg)
            case .greaterThan:
                return NSPredicate(format: "%K > %@", filter.field, filter.value as! CVarArg)
            case .contains:
                return NSPredicate(format: "%K CONTAINS %@", filter.field, filter.value as! CVarArg)
            }
        }

        switch logicalOperator {
        case .not:
            return nil
        case .and:
            return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        case .or:
            return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        @unknown default:
            return nil
        }
    }
    // MARK: - Private Methods

    // Publisher for database updates
    private let updateSubject = PassthroughSubject<Void, Never>()

    func fetchCount(types: [NEAssetType]?) async throws -> Int {
        let predicate = createCompoundPredicate(from: createQueryFilters(types: types), logicalOperator: .or)
        return try await persistentContainer.performBackgroundTask { context in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Asset")
            fetchRequest.resultType = .countResultType
            fetchRequest.predicate = predicate
            let count = try context.count(for: fetchRequest)
            return count
        }
    }

    private func createQueryFilters(types: [NEAssetType]?) -> [QueryFilter]? {
        guard let types else { return nil }
        return types.map { QueryFilter(field: "type", value: $0.stringValue, comparison: .equal) }
    }

    var didUpdatePublisher: AnyPublisher<NestDatabase, Never> {
        updateSubject
            .compactMap { [weak self] in
                guard let self else { return nil }
                return self
            }
            .eraseToAnyPublisher()
    }

    private var subscriptions: Set<AnyCancellable> = Set()

    private func installBindings() {
        let notificationCenter = NotificationCenter.default
        let savePublisher = notificationCenter.publisher(
            for: NSManagedObjectContext.didSaveObjectIDsNotification,
            object: viewContext
        )
        let changePublisher = notificationCenter.publisher(
            for: NSManagedObjectContext.didChangeObjectsNotification,
            object: viewContext
        )
        let mergePublisher = notificationCenter.publisher(
            for: NSManagedObjectContext.didMergeChangesObjectIDsNotification,
            object: viewContext
        )
        Publishers
            .MergeMany(savePublisher, changePublisher, mergePublisher)
            .map { _ in () }
            .throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)
            .subscribe(updateSubject)
            .store(in: &subscriptions)
    }
}

// MARK - Type Conversions

extension NestAsset {
    /// Converts a `NestAsset` to a CoreData `Asset`.
    /// - Parameter context: The CoreData context where the `Asset` will be created.
    /// - Returns: A new `Asset` instance.
    func toCoreDataAsset(in context: NSManagedObjectContext) -> Asset {
        let asset = Asset(context: context)
        asset.id = id
        asset.type = type.stringValue
        asset.metadata = metadataToJSONString(metadata)
        asset.createdAt = createdAt
        asset.modifiedAt = modifiedAt
        asset.fileSize = Int64(fileSize ?? 0)
        return asset
    }

    func metadataJSONString() -> String? {
        metadataToJSONString(metadata)
    }

    /// Converts metadata dictionary to a JSON string.
    /// - Parameter metadata: The dictionary to convert.
    /// - Returns: A JSON string or `nil` if conversion fails.
    func metadataToJSONString(_ metadata: [String: MetadataValue]?) -> String? {
        guard let metadata else { return nil }
        guard let data = try? JSONEncoder().encode(metadata) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Asset {
    func toNEAsset() -> NEAsset {
        return NestAsset(
            id: id ?? "",
            type: NestAssetType(stringValue: type!),
            createdAt: createdAt!,
            modifiedAt: modifiedAt,
            fileSize: Int(fileSize),
            metadata: metadataToDictionary(metadata)
        )
    }

    /// Converts a JSON string to a dictionary of metadata.
    /// - Parameter metadata: A JSON string representing the metadata.
    /// - Returns: A dictionary of metadata if conversion is successful; otherwise, `nil`.
    private func metadataToDictionary(_ metadata: String?) -> [String: MetadataValue]? {
        guard let metadata else { return nil }
        guard let data = metadata.data(using: .utf8) else { return nil }
        do {
            let decoded = try JSONDecoder().decode([String: MetadataValue].self, from: data)
            return decoded
        } catch {
            print("Failed to decode metadata: \(error)")
            return nil
        }
    }
}
