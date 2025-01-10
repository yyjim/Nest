//
//  Mock.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Combine
import Foundation
@testable import Nest

final class MockDatabase: NestDatabase {
    @Published
    var storedAssets: [String: NestAsset] = [:]

    private var assets: [NestAsset] {
        storedAssets.values.sorted { $0.createdAt < $1.createdAt }
    }

    func add(_ asset: NestAsset) async throws {
        guard storedAssets[asset.id] == nil else {
            throw NSError(
                domain: "MockDatabaseError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "The asset with ID \(asset.id) already exists."]
            )
        }
        storedAssets[asset.id] = asset
    }

    func update(_ asset: NEAsset) async throws {
        storedAssets[asset.id] = asset
    }

    func fetch(byId id: String) async throws -> NestAsset? {
        storedAssets[id]
    }

    func delete(byId id: String) async throws {
        storedAssets[id] = nil
    }

    func fetchAll(filters: [QueryFilter]) async throws -> [NestAsset] {
        assets
    }

    func fetch(limit: Int, offset: Int, filters: [QueryFilter], ascending: Bool) async throws -> [NestAsset] {
        let sortedAssets: [NestAsset] = storedAssets.values.sorted {
            ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
        }
        let paginatedAssets = sortedAssets.dropFirst(offset).prefix(limit)
        return Array(paginatedAssets)
    }

    func deleteAll() async throws {
        storedAssets = [:]
    }

    func fetchCount(types: [NEAssetType]?) async throws -> Int {
        guard let types else {
            return storedAssets.count
        }
        return storedAssets.values.filter { types.contains($0.type) }.count
    }

    var didUpdatePublisher: AnyPublisher<NestDatabase, Never> {
        $storedAssets
            .compactMap { [weak self] _ in
                guard let self = self else { return nil }
                return self
            }
            .eraseToAnyPublisher()
    }
}
