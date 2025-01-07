//
//  CoreDataAssetManager.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Foundation
import CoreData

class CoreDataAssetDatabase: NestDatabase {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Adds a new asset or updates an existing one in the database.
    /// - Parameter asset: The `NEAsset` to be added or updated.
    /// - Throws: An error if saving to the database fails.
    func add(_ asset: NEAsset) throws {
        let newAsset = asset.toCoreDataAsset(in: context)
        context.insert(newAsset)
        try context.save()
    }

    func update(_ asset: NEAsset) throws {
        guard let coreDataAsset = try fetchCoreDataAsset(byId: asset.id) else {
            throw NestError.assetNotFound
        }
        // Update the existing record
        coreDataAsset.type = asset.type.stringValue
        coreDataAsset.metadata = asset.metadataJSONString()
        coreDataAsset.fileSize = asset.fileSize.map { Int64($0) } ?? 0
        coreDataAsset.modifiedAt = Date()
        try context.save()
    }

    /// Fetches a CoreData asset entity by its unique identifier.
    /// - Parameter id: The unique identifier of the asset to fetch.
    /// - Returns: The `Asset` entity if found.
    /// - Throws: `NestError.dataNotFound` if the asset does not exist in the database.
    private func fetchCoreDataAsset(byId id: String) throws -> Asset? {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        return try context.fetch(request).first
    }

    func fetch(byId id: String) throws -> NEAsset? {
        guard let coreDataAsset = try fetchCoreDataAsset(byId: id) else {
            return nil
        }
        return coreDataAsset.toNEAsset()
    }

    func delete(byId id: String) throws {
        guard let coreDataAsset = try fetchCoreDataAsset(byId: id) else {
            return
        }
        context.delete(coreDataAsset)
        try context.save()
    }

    func fetchAll(filters: [QueryFilter]) throws -> [NEAsset] {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = createCompoundPredicate(from: filters)
        return try context.fetch(request).map { $0.toNEAsset() }
    }

    func fetch(limit: Int, offset: Int, filters: [QueryFilter]) throws -> [NEAsset] {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.fetchLimit = limit
        request.fetchOffset = offset
        request.predicate = createCompoundPredicate(from: filters)
        return try context.fetch(request).map { $0.toNEAsset() }
    }

    func deleteAll() async throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Asset")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        try context.save()
    }

    private func createCompoundPredicate(from filters: [QueryFilter]) -> NSPredicate? {
        guard !filters.isEmpty else { return nil }
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
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
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
