//
//  Nest.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation

public class AssetsNest: @unchecked Sendable {
    private let storage: NestStorage
    private let database: NestDatabase

    public enum AssetIdentifier {
        case id(String)
        case assetURL(URL)

        func identifier() throws -> String {
            switch self {
            case let .id(id):
                return id
            case let .assetURL(url):
                guard let id = NEAsset.identifier(from: url) else {
                    throw NestError.invalidAssetURL
                }
                return id
            }
        }
    }

    /// Shared instance using `LocalStorage` and CoreData.
    public static let sharedLocal: AssetsNest = {
        let storage = LocalStorage(directory: .documents)
        let database = CoreDataAssetDatabase(context: CoreDataManager.shared.context)
        return AssetsNest(storage: storage, database: database)
    }()

    /// Initializes the `Nest` framework with the provided storage and database implementations.
    /// - Parameters:
    ///   - storage: The storage implementation for handling file operations.
    ///   - database: The database implementation for managing asset metadata.
    public init(storage: NestStorage, database: NestDatabase) {
        self.storage = storage
        self.database = database
    }

    /// Creates a new asset along with its data in the storage and database.
    /// - Parameters:
    ///   - data: The binary data to save.
    ///   - type: The type of the asset (e.g., photo, video, etc.).
    ///   - metadata: Additional metadata to associate with the asset (optional).
    /// - Returns: The newly created `NEAsset`.
    /// - Throws: `NestError.assetAlreadyExists` if a conflict occurs during asset creation.
    @discardableResult
    public func createAsset(
        data: Data,
        type: NEAssetType,
        metadata: [String: MetadataValue]? = nil
    ) async throws -> NEAsset {
        let asset = NEAsset(
            id: UUID().uuidString,
            type: type,
            createdAt: .now,
            modifiedAt: nil,
            fileSize: data.count,
            metadata: metadata
        )
        try await saveAsset(asset, data: data, isNew: true)
        return asset
    }

    /// Updates an existing asset by its ID and associated data in the storage and database.
    /// - Parameters:
    ///   - id: The unique identifier of the asset to update.
    ///   - data: The binary data associated with the asset.
    ///   - metadata: Additional metadata to update the asset with (optional).
    /// - Throws: `NestError.assetNotFound` if the asset does not exist.
    public func updateAsset(
        assetIdentifier: AssetIdentifier,
        data: Data,
        type: NEAssetType? = nil,
        metadata: [String: MetadataValue]? = nil
    ) async throws {
        let existingAsset = try await fetchAsset(assetIdentifier: assetIdentifier)
        let updatedAsset = NEAsset(
            id: existingAsset.id,
            type: type ?? existingAsset.type,
            createdAt: existingAsset.createdAt,
            modifiedAt: .now,
            fileSize: data.count,
            metadata: metadata ?? existingAsset.metadata
        )
        try await updateAsset(asset: updatedAsset, data: data)
    }

    /// Updates an existing asset with new data.
    public func updateAsset(asset: NEAsset, data: Data) async throws {
        try await saveAsset(asset, data: data, isNew: false)
    }

    /// Saves or updates an asset along with its data in the storage and database.
    /// - Parameters:
    ///   - asset: The `NEAsset` to save or update.
    ///   - data: The binary data associated with the asset.
    /// - Throws: An error if saving to the storage or database fails.
    private func saveAsset(_ asset: NEAsset, data: Data, isNew: Bool) async throws {
        // Save the file data to storage
        try await storage.write(data: data, assetIdentifier: asset.id)
        // Save or update the metadata in the database
        if isNew {
            try await database.add(asset)
        } else {
            try await database.update(asset)
        }
    }

    /// Deletes an asset, including its data and metadata.
    /// - Parameter id: The unique identifier of the asset to delete.
    public func deleteAsset(assetIdentifier: AssetIdentifier) async throws {
        let asset = try await fetchAsset(assetIdentifier: assetIdentifier)
        try await deleteAsset(asset: asset)
    }

    /// Deletes an asset, including its data and metadata.
    public func deleteAsset(asset: NEAsset) async throws {
        do {
            try await storage.deleteData(assetIdentifier: asset.id)
        } catch NestError.dataNotFound {
            // Ignore this error as the asset may still exist in the database
        } catch {
            throw error
        }
        // Always attempt to delete the asset from the database
        try await database.delete(byId: asset.id)
    }

    // Delete all assets from the database. Currently intended for internal use only.
    func deleteAllAssets() async throws {
        try await database.deleteAll()
        try await storage.deleteAll()
    }

    /// Fetches an asset's metadata.
    /// - Parameter id: The unique identifier of the asset to fetch.
    /// - Returns: The asset metadata (`NEAsset`) if it exists in the database.
    /// - Throws: `NestError.assetNotFound` if the asset metadata is not found in the database.
    public func fetchAsset(assetIdentifier: AssetIdentifier) async throws -> NEAsset {
        let identifier = try assetIdentifier.identifier()
        guard let asset = try await database.fetch(byId: identifier) else {
            throw NestError.assetNotFound
        }
        return asset
    }

    /// Fetches the binary data associated with an asset.
    /// - Parameter id: The unique identifier of the asset whose data is to be fetched.
    /// - Returns: The binary data (`Data`) associated with the asset stored in the storage.
    /// - Throws: `NestError.dataNotFound` if the asset metadata or binary data is not found.
    public func fetchAssetData(assetIdentifier: AssetIdentifier) async throws -> Data {
        let asset = try await fetchAsset(assetIdentifier: assetIdentifier)
        return try await fetchAssetData(asset: asset)
    }

    /// Fetches the binary data associated with an asset.
    public func fetchAssetData(asset: NEAsset) async throws -> Data {
        try await storage.readData(assetIdentifier: asset.id)
    }

    /// Fetches all assets matching the given filters.
    /// - Parameter filters: The filters to apply.
    /// - Returns: An array of matching `NEAsset` objects.
    public func fetchAllAssets(filters: [QueryFilter]) async throws -> [NEAsset] {
        try await database.fetchAll(filters: filters)
    }

    // Fetches all `NEAsset` objects with the given type.
    public func fetchAllAssets(type: NestAssetType? = nil) async throws -> [NEAsset] {
        try await database.fetchAll(type: type)
    }

    /// Fetches assets with pagination and filters.
    /// - Parameters:
    ///   - limit: The maximum number of assets to fetch.
    ///   - offset: The offset to start fetching from.
    ///   - filters: The filters to apply.
    /// - Returns: An array of matching `NEAsset` objects.
    public func fetchAssets(limit: Int, offset: Int, filters: [QueryFilter]) async throws -> [NEAsset] {
        try await database.fetch(limit: limit, offset: offset, filters: filters)
    }

    // Fetches `NEAsset` objects with pagination for given type.
    public func fetchAssets(limit: Int, offset: Int, type: NEAssetType) async throws -> [NEAsset] {
        try await database.fetch(limit: limit, offset: offset, type: type)
    }
}
