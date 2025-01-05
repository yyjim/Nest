import Testing
import Foundation
@testable import Nest

extension Nest {
    static let mock: Nest = {
        let storage = MockStorage()
        let database = MockDatabase()
        return Nest(storage: storage, database: database)
    }()
}

@Test func testNestCURD() async throws {
    // NOTE: The @Test(arguments: [Nest.localShared, Nest.mock ]) doesn't work, so we have to test them separately
    // Test with Nest.Mock
    try await performCURDTest(using: Nest.mock)

    // Test with Nest.localShared
    try await performCURDTest(using: Nest.localShared)
}

// Helper function to perform CURD test
private func performCURDTest(using nest: Nest) async throws {
    let data = Data(repeating: 0, count: 1024)
    let metadata: [String: MetadataValue] = ["format": .string("png")]

    // Create: Create the asset
    let asset = try await nest.createAsset(data: data, type: .photo, metadata: metadata)

    // Read: Fetch the asset and verify the data
    let fetchedAsset = try await nest.fetchAsset(byId: asset.id)
    let fetchedData = try await nest.fetchAssetData(byId: asset.id)
    #expect(fetchedAsset.id == asset.id)
    #expect(fetchedAsset.metadata == metadata)
    #expect(fetchedData == data)

    // Update: Modify the asset metadata and re-save
    let updatedData = Data(repeating: 0, count: 512)
    let updatedMetadata: [String: MetadataValue] = ["format": .string("jpeg")]
    try await nest.updateAsset(byId: asset.id, data: updatedData, metadata: updatedMetadata)
    let updatedFetchedAsset = try await nest.fetchAsset(byId: asset.id)
    let updatedFetchedData = try await nest.fetchAssetData(byId: asset.id)
    #expect(updatedFetchedAsset.id == asset.id)
    #expect(updatedFetchedAsset.metadata == updatedMetadata)
    #expect(updatedFetchedData == updatedData)

    // Delete: Remove the asset and verify deletion
    try await nest.deleteAsset(byId: asset.id)
    await #expect(throws: NestError.assetNotFound) {
        try await nest.fetchAsset(byId: asset.id)
    }
}
