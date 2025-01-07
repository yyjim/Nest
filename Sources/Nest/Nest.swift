//
//  Nest.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation

public class Nest: @unchecked Sendable {
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
    public static let localShared: Nest = {
        let storage = LocalStorage(directory: .documents)
        let database = CoreDataAssetDatabase(context: CoreDataManager.shared.context)
        return Nest(storage: storage, database: database)
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
    public func createAsset(
        data: Data,
        type: NEAssetType,
        metadata: [String: MetadataValue]? = nil
    ) async throws -> NEAsset {
        // Create the new asset
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
        try await saveAsset(updatedAsset, data: data, isNew: false)
    }

    /// Saves or updates an asset along with its data in the storage and database.
    /// - Parameters:
    ///   - asset: The `NEAsset` to save or update.
    ///   - data: The binary data associated with the asset.
    /// - Throws: An error if saving to the storage or database fails.
    private func saveAsset(_ asset: NEAsset, data: Data, isNew: Bool) async throws {
        // Save the file data to storage
        try await storage.write(data: data, forAsset: asset)
        // Save or update the metadata in the database
        if isNew {
            try database.add(asset)
        } else {
            try database.update(asset)
        }
    }

    /// Deletes an asset, including its data and metadata.
    /// - Parameter id: The unique identifier of the asset to delete.
    public func deleteAsset(assetIdentifier: AssetIdentifier) async throws {
        // Fetch the asset metadata from the database
        let identifier = try assetIdentifier.identifier()
        guard let asset = try database.fetch(byId: identifier) else {
            throw NestError.assetNotFound
        }
        // Delete the file from storage
        try await storage.deleteData(forAsset: asset)
        // Remove the metadata from the database
        try database.delete(byId: identifier)
    }

    /// Fetches an asset's metadata.
    /// - Parameter id: The unique identifier of the asset to fetch.
    /// - Returns: The asset metadata (`NEAsset`) if it exists in the database.
    /// - Throws: `NestError.assetNotFound` if the asset metadata is not found in the database.
    public func fetchAsset(assetIdentifier: AssetIdentifier) async throws -> NEAsset {
        let identifier = try assetIdentifier.identifier()
        guard let asset = try database.fetch(byId: identifier) else {
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
        return try await storage.readData(forAsset: asset)
    }

    /// Fetches all assets matching the given filters.
    /// - Parameter filters: The filters to apply.
    /// - Returns: An array of matching `NEAsset` objects.
    public func fetchAllAssets(filters: [QueryFilter]) throws -> [NEAsset] {
        try database.fetchAll(filters: filters)
    }

    /// Fetches assets with pagination and filters.
    /// - Parameters:
    ///   - limit: The maximum number of assets to fetch.
    ///   - offset: The offset to start fetching from.
    ///   - filters: The filters to apply.
    /// - Returns: An array of matching `NEAsset` objects.
    public func fetchAssets(limit: Int, offset: Int, filters: [QueryFilter]) throws -> [NEAsset] {
        try database.fetch(limit: limit, offset: offset, filters: filters)
    }
}
