import Testing
import UIKit
import Foundation
@testable import Nest

extension AssetsNest {
    static let mock: AssetsNest = {
        let storage = MockStorage()
        let database = MockDatabase()
        return AssetsNest(storage: storage, database: database)
    }()
}

@Test
func testFetchAssets() async throws {
    let nest = AssetsNest.sharedLocal
    try await nest.deleteAllAssets()
    #expect(try! nest.fetchAllAssets().isEmpty)

    // Helper function to create assets
    func createDummyAssets(type: NEAssetType, count: Int) async throws {
        let data = Data(repeating: 0, count: 1)
        for _ in 1...count {
            try await nest.createAsset(data: data, type: type, metadata: nil)
        }
    }

    // Create assets
    try await createDummyAssets(type: .photo, count: 20)
    try await createDummyAssets(type: .video, count: 10)
    try await createDummyAssets(type: .custom("sticker"), count: 5)

    // Validate asset counts
    #expect(try! nest.fetchAllAssets(type: .photo).count == 20)
    #expect(try! nest.fetchAllAssets(type: .video).count == 10)
    #expect(try! nest.fetchAllAssets(type: .custom("sticker")).count == 5)
    #expect(try! nest.fetchAllAssets().count == 20 + 10 + 5)
}

@Test func testAssetsNestCURD() async throws {
    // NOTE: The @Test(arguments: [AssetsNest.sharedLocal, AssetsNest.mock]) doesn't work, so we have to test them separately
    // Test with AssetsNest.Mock
    try await performCURDTest(using: AssetsNest.mock)

    // Test with AssetsNest.sharedLocal
    try await performCURDTest(using: AssetsNest.sharedLocal)
}

// Helper function to perform CURD test
private func performCURDTest(using nest: AssetsNest) async throws {
    try await nest.deleteAllAssets()
    #expect(try! nest.fetchAllAssets().count == 0)

    let data = Data(repeating: 0, count: 1024)
    let metadata: [String: MetadataValue] = ["format": .string("png")]

    // Create: Create the asset
    let asset = try await nest.createAsset(data: data, type: .photo, metadata: metadata)

    // Read: Fetch the asset and verify the data
    let fetchedAsset = try await nest.fetchAsset(assetIdentifier: .id(asset.id))
    let fetchedData = try await nest.fetchAssetData(assetIdentifier: .id(asset.id))
    #expect(fetchedAsset.id == asset.id)
    #expect(fetchedAsset.metadata == metadata)
    #expect(fetchedData == data)

    // Update: Modify the asset metadata and re-save
    let updatedData = Data(repeating: 0, count: 512)
    let updatedMetadata: [String: MetadataValue] = ["format": .string("jpeg")]
    try await nest.updateAsset(assetIdentifier: .id(asset.id), data: updatedData, metadata: updatedMetadata)
    let updatedFetchedAsset = try await nest.fetchAsset(assetIdentifier: .id(asset.id))
    let updatedFetchedData = try await nest.fetchAssetData(assetIdentifier: .id(asset.id))
    #expect(updatedFetchedAsset.id == asset.id)
    #expect(updatedFetchedAsset.metadata == updatedMetadata)
    #expect(updatedFetchedData == updatedData)

    // Delete: Remove the asset and verify deletion
    try await nest.deleteAsset(assetIdentifier: .id(asset.id))
    await #expect(throws: NestError.assetNotFound) {
        try await nest.fetchAsset(assetIdentifier: .id(asset.id))
    }
}

@Test func testImageCURD() async throws {
    // Test with AssetsNest.Mock
    try await performImageCURDTest(using: AssetsNest.mock)

    // Test with AssetsNest.sharedLocal
    try await performImageCURDTest(using: AssetsNest.sharedLocal)
}

// Helper function to perform CURD test for images
private func performImageCURDTest(using nest: AssetsNest) async throws {
    func generateTestImage(size: CGSize = CGSize(width: 10, height: 10), color: UIColor = .blue) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }

    let image = generateTestImage()
    let format = ImageFormat.png

    // Create: Save the image
    let imageAsset = try await nest.create(
        image: image,
        format: format,
        type: .custom("image"),
        metadata: ["tag": .string("image")]
    )

    // Read: Fetch the image and verify it
    let fetchedImageAsset = try await nest.fetchAsset(assetIdentifier: .id(imageAsset.id))
    let fetchedImage = try await nest.readImage(assetIdentifier: .id(imageAsset.id))
    #expect(fetchedImageAsset.type == .custom("image"))
    #expect(fetchedImageAsset.metadata ==  ["tag": .string("image")])
    #expect(fetchedImage != nil)
    #expect(ImageComparator.compareImages(fetchedImage, image))

    // Update: Modify the image and re-save
    let updatedImage = generateTestImage(size: CGSize(width: 20, height: 20), color: .red)
    try await nest.update(
        assetIdentifier: .id(imageAsset.id),
        image: updatedImage,
        format: .png,
        type: .custom("sticker"),
        metadata: ["tag": .string("sticker")]
    )
    let updatedImageAsset = try await nest.fetchAsset(assetIdentifier: .id(imageAsset.id))
    let updatedFetchedImage = try await nest.readImage(assetIdentifier: .id(imageAsset.id))
    #expect(updatedImageAsset.type == .custom("sticker"))
    #expect(updatedImageAsset.metadata == ["tag": .string("sticker")])
    #expect(updatedFetchedImage != nil)
    #expect(ImageComparator.compareImages(updatedFetchedImage, updatedImage))

    // Delete: Remove the image and verify deletion
    try await nest.deleteImage(assetIdentifier: .id(imageAsset.id))
    await #expect(throws: NestError.assetNotFound) {
        try await nest.readImage(assetIdentifier: .id(imageAsset.id))
    }
}

private class ImageComparator {
    /// Redraws an image using UIImageRenderer to normalize its representation
    static func normalizeImage(_ image: UIImage) -> UIImage? {
        let renderSize = image.size
        let renderer = UIGraphicsImageRenderer(size: renderSize)
        return renderer.image { context in
            // Fill with clear color first to ensure consistent background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: renderSize))
            // Draw the image
            image.draw(in: CGRect(origin: .zero, size: renderSize))
        }
    }

    /// Compares two images by normalizing them first and then comparing their PNG data
    static func compareImages(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let normalizedImage1 = normalizeImage(image1),
              let normalizedImage2 = normalizeImage(image2),
              let data1 = normalizedImage1.pngData(),
              let data2 = normalizedImage2.pngData() else {
            return false
        }
        return data1 == data2
    }
}
