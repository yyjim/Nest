//
//  MockStorage.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import Foundation
@testable import Nest

final class MockStorage: NestStorage {
    var savedData: [String: Data] = [:]

    func write(data: Data, forAsset asset: NestAsset) async throws {
        savedData[asset.id] = data
    }

    func readData(forAsset asset: NestAsset) async throws -> Data {
        guard let data = savedData[asset.id] else {
            throw NestError.dataNotFound
        }
        return data
    }

    func deleteData(forAsset asset: NestAsset) async throws {
        savedData.removeValue(forKey: asset.id)
    }

    func dataExists(forAsset asset: NestAsset) async -> Bool {
        return savedData[asset.id] != nil
    }

    func deleteAll() async throws {
        savedData.removeAll()
    }
}
