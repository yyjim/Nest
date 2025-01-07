//
//  NestStorage.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation

public protocol NestStorage {
    /// Asynchronously writes data for a specified asset.
    func write(data: Data, assetIdentifier: String) async throws

    /// Asynchronously reads data for a specified asset.
    func readData(assetIdentifier: String) async throws -> Data

    /// Asynchronously deletes data associated with the specified asset.
    func deleteData(assetIdentifier: String) async throws

    /// Asynchronously checks if data exists for the specified asset in storage.
    func dataExists(assetIdentifier: String) async -> Bool

    /// Asynchronously delete all data
    func deleteAll() async throws
}
