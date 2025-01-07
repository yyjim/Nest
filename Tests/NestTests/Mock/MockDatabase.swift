//
//  Mock.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Foundation
@testable import Nest

final class MockDatabase: NestDatabase {
    var storedAssets: [String: NestAsset] = [:]

    private var assets: [NestAsset] {
        storedAssets.values.sorted { $0.createdAt < $1.createdAt }
    }

    func add(_ asset: NestAsset) throws {
        guard storedAssets[asset.id] == nil else {
            throw NSError(
                domain: "MockDatabaseError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "The asset with ID \(asset.id) already exists."]
            )
        }
        storedAssets[asset.id] = asset
    }

    func update(_ asset: NEAsset) throws {
        storedAssets[asset.id] = asset
    }

    func fetch(byId id: String) throws -> NestAsset? {
        storedAssets[id]
    }

    func delete(byId id: String) throws {
        storedAssets[id] = nil
    }

    func fetchAll(filters: [QueryFilter]) throws -> [NestAsset] {
        assets
    }

    func fetch(limit: Int, offset: Int, filters: [QueryFilter]) throws -> [NestAsset] {
        Array(assets[offset..<(offset + limit)])
    }

    func deleteAll() throws {
        storedAssets = [:]
    }
}
