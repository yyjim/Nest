//
//  NestDatabase.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

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
    func add(_ asset: NEAsset) throws

    /// Updates an `NEAsset` in the database.
    /// - Parameter asset: The `NEAsset` to update.
    func update(_ asset: NEAsset) throws

    /// Fetches an `NEAsset` by its unique identifier.
    /// - Parameter id: The unique identifier of the asset.
    /// - Returns: The fetched `NEAsset` or `nil` if not found.
    func fetch(byId id: String) throws -> NEAsset?

    /// Deletes an `NEAsset` by its unique identifier.
    /// - Parameter id: The unique identifier of the asset to delete.
    func delete(byId id: String) throws

    /// Fetches all `NEAsset` objects matching the given filters.
    /// - Parameter filters: Filters to apply for querying.
    /// - Returns: An array of matching `NEAsset` objects.
    func fetchAll(filters: [QueryFilter]) throws -> [NEAsset]

    /// Fetches `NEAsset` objects with pagination and filters.
    /// - Parameters:
    ///   - limit: The maximum number of entities to fetch.
    ///   - offset: The offset to start fetching from.
    ///   - filters: Filters to apply for querying.
    /// - Returns: An array of matching `NEAsset` objects.
    func fetch(limit: Int, offset: Int, filters: [QueryFilter]) throws -> [NEAsset]
}
