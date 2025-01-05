//
//  Nest+Image.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import UIKit

extension Nest {
    /// Saves a `UIImage` with the specified format.
    /// - Parameters:
    ///   - image: The `UIImage` to save.
    ///   - format: The desired image format.
    /// - Throws: An error if the operation fails.
    public func write(image: UIImage, format: ImageFormat) async throws -> NEAsset{
        guard let imageData = format.data(from: image) else {
            throw NestError.unableToConvertToData
        }
        return try await createAsset(
            data: imageData,
            type: .photo,
            metadata: ["format": .string(format.fileExtension)]
        )
    }

    /// Reads a `UIImage` by its unique identifier.
    /// - Parameter id: The unique identifier of the image.
    /// - Returns: The `UIImage` if found.
    /// - Throws: An error if the operation fails or the image cannot be decoded.
    public func readImage(byId id: String) async throws -> UIImage {
        let imageData = try await fetchAssetData(byId: id)
        guard let image = UIImage(data: imageData) else {
            throw NestError.failedToReadData(underlyingError: nil)
        }
        return image
    }

    /// Reads a `UIImage` by its assetURL.
    /// - Parameter assetURL: The assetURL of the image.
    /// - Returns: The `UIImage` if found.
    /// - Throws: An error if the operation fails or the image cannot be decoded.
    public func readImage(byAssetURL assetURL: URL) async throws -> UIImage {
        guard let uniqueID = NestAsset.identifier(from: assetURL) else {
            throw NestError.invalidAssetURL
        }
        let image = try await readImage(byId: uniqueID)
        return image
    }

    /// Deletes an image by its unique identifier.
    /// - Parameter id: The unique identifier of the image to delete.
    /// - Throws: An error if the operation fails.
    public func deleteImage(byId id: String) async throws {
        try await deleteAsset(byId: id)
    }
}
