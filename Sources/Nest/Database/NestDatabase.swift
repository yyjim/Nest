//
//  NestDatabase.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Combine

public struct QueryFilter {
    public let field: String
    public let value: Any
    public let comparison: ComparisonType

    public enum ComparisonType {
        case equal
        case lessThan
        case greaterThan
        case contains
    }
}

public protocol NestDatabase {
    /// Adds an `NEAsset` to the database.
    /// - Parameter asset: The `NEAsset` to add.
    func add(_ asset: NEAsset) async throws

    /// Updates an `NEAsset` in the database.
    /// - Parameter asset: The `NEAsset` to update.
    func update(_ asset: NEAsset) async throws

    /// Fetches an `NEAsset` by its unique identifier.
    /// - Parameter id: The unique identifier of the asset.
    /// - Returns: The fetched `NEAsset` or `nil` if not found.
    func fetch(byId id: String) async throws -> NEAsset?

    /// Deletes an `NEAsset` by its unique identifier.
    /// - Parameter id: The unique identifier of the asset to delete.
    func delete(byId id: String) async throws

    /// Fetches all `NEAsset` objects matching the given filters.
    /// - Parameters
    ///   - filters: Filters to apply for querying.
    ///   - ascending: A Boolean indicating the sorting order of the creation date.
    /// - Returns: An array of matching `NEAsset` objects.
    func fetchAll(filters: [QueryFilter], ascending: Bool) async throws -> [NEAsset]

    // Fetches all `NEAsset` objects with the given type.
    func fetchAll(type: NEAssetType?, ascending: Bool) async throws -> [NEAsset]

    /// Fetches `NEAsset` objects with pagination and filters.
    /// - Parameters:
    ///   - limit: The maximum number of entities to fetch.
    ///   - offset: The offset to start fetching from.
    ///   - filters: Filters to apply for querying.
    ///   - ascending: A Boolean indicating the sorting order of the creation date.
    /// - Returns: An array of matching `NEAsset` objects.
    func fetch(limit: Int, offset: Int, filters: [QueryFilter], ascending: Bool) async throws -> [NEAsset]

    // Fetches `NEAsset` objects with pagination for given type.
    func fetch(limit: Int, offset: Int, type: NEAssetType?, ascending: Bool) async throws -> [NEAsset]

    // Delete all
    func deleteAll() async throws

    /// Retrieves the total count of items in the database, optionally filtered by specific types.
    /// - Parameter types: An optional array of `NEAssetType` to filter the count. If `nil`, counts all items.
    /// - Returns: The total number of items matching the specified types, or all items if no types are provided.
    func fetchCount(types: [NEAssetType]?) async throws -> Int

    // MARK: - Publisher

    /// Publisher that emits when the database content has been updated
    var didUpdatePublisher: AnyPublisher<NestDatabase, Never> { get }
}

extension NestDatabase {
    public func fetchAll(ascending: Bool) async throws -> [NEAsset] {
        try await fetchAll(type: nil, ascending: ascending)
    }

    public func fetch(limit: Int, offset: Int, ascending: Bool) async throws -> [NEAsset] {
        try await fetch(limit: limit, offset: offset, type: nil, ascending: ascending)
    }

    func fetchAll(filters: [QueryFilter], ascending: Bool) async throws -> [NEAsset] {
        try await fetch(limit: 0, offset: 0, filters: filters, ascending: ascending)
    }

    func fetch(limit: Int, offset: Int, type: NEAssetType?, ascending: Bool) async throws -> [NEAsset] {
        try await fetch(
            limit: limit,
            offset: offset,
            filters: createQueryFilters(type: type) ?? [],
            ascending: ascending
        )
    }

    func fetchAll(type: NEAssetType?, ascending: Bool) async throws -> [NEAsset] {
        try await fetchAll(filters: createQueryFilters(type: type) ?? [], ascending: ascending)
    }

    func fetchCount(type: NEAssetType) async throws -> Int {
        try await fetchCount(types: [type])
    }

    private func createQueryFilters(type: NEAssetType?) -> [QueryFilter]? {
        guard let type else { return nil }
        return [QueryFilter(field: "type", value: type.stringValue, comparison: .equal)]
    }
}
