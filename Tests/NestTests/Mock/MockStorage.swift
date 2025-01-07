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

    func write(data: Data, assetIdentifier: String) async throws {
        savedData[assetIdentifier] = data
    }

    func readData(assetIdentifier: String) async throws -> Data {
        guard let data = savedData[assetIdentifier] else {
            throw NestError.dataNotFound
        }
        return data
    }

    func deleteData(assetIdentifier: String) async throws {
        savedData.removeValue(forKey: assetIdentifier)
    }

    func dataExists(assetIdentifier: String) async -> Bool {
        return savedData[assetIdentifier] != nil
    }

    func deleteAll() async throws {
        savedData.removeAll()
    }
}
