//
//  Nest+Image.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import UIKit

extension AssetsNest {
    /// Saves a `UIImage` with the specified format.
    /// - Parameters:
    ///   - image: The `UIImage` to save.
    ///   - format: The desired image format.
    /// - Throws: An error if the operation fails.
    public func create(
        image: UIImage,
        format: ImageFormat,
        type: NEAssetType = .photo,
        metadata: [String: MetadataValue]? = nil
    ) async throws -> NEAsset{
        guard let imageData = format.data(from: image) else {
            throw NestError.unableToConvertToData
        }
        return try await createAsset(data: imageData, type: type, metadata: metadata)
    }

    /// Updates an existing asset's image with the specified format.
    /// - Parameters:
    ///   - image: The new `UIImage` to save.
    ///   - format: The desired image format.
    ///   - id: The unique identifier of the asset to update.
    /// - Throws:
    ///   - `NestError.unableToConvertToData` if the image cannot be converted to data.
    ///   - `NestError.assetNotFound` if the asset does not exist.
    ///   - Other errors if the operation fails.
    public func update(
        assetIdentifier: AssetIdentifier,
        image: UIImage,
        format: ImageFormat,
        type: NEAssetType? = nil,
        metadata: [String: MetadataValue]? = nil
    ) async throws {
        // Convert the image to the specified format
        guard let imageData = format.data(from: image) else {
            throw NestError.unableToConvertToData
        }
        // Update the asset with the new data and metadata
        try await updateAsset(
            assetIdentifier: assetIdentifier,
            data: imageData,
            type: type,
            metadata: metadata
        )
    }

    /// Reads a `UIImage` by its unique identifier.
    /// - Parameter id: The unique identifier of the image.
    /// - Returns: The `UIImage` if found.
    /// - Throws: An error if the operation fails or the image cannot be decoded.
    public func readImage(assetIdentifier: AssetIdentifier) async throws -> UIImage {
        let imageData = try await fetchAssetData(assetIdentifier: assetIdentifier)
        guard let image = UIImage(data: imageData) else {
            throw NestError.failedToReadData(underlyingError: nil)
        }
        return image
    }

    /// Deletes an image by its unique identifier.
    /// - Parameter id: The unique identifier of the image to delete.
    /// - Throws: An error if the operation fails.
    public func deleteImage(assetIdentifier: AssetIdentifier) async throws {
        try await deleteAsset(assetIdentifier: assetIdentifier)
    }
}
