//
//  NestStorage+UIImage.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation
import UIKit

public extension NestStorage {
    /// Writes a UIImage to storage for the specified asset.
    func write(image: UIImage, forAsset asset: NestAsset, format: ImageFormat = .png) async throws {
        guard let imageData = format.data(from: image) else {
            throw NestError.unableToConvertToData
        }
        try await write(data: imageData, assetIdentifier: asset.id)
    }

    /// Reads a UIImage from storage for the specified asset.
    func readImage(forAsset asset: NestAsset) async throws -> UIImage {
        let imageData: Data
        do {
            imageData = try await readData(assetIdentifier: asset.id)
        } catch {
            throw NestError.failedToReadData(underlyingError: nil)
        }
        guard let image = UIImage(data: imageData) else {
            throw NestError.unableToConvertToData
        }
        return image
    }
}

public enum ImageFormat {
    case png
    case jpeg(compressionQuality: CGFloat)

    /// Provides the corresponding `UIImage` data format.
    func data(from image: UIImage) -> Data? {
        switch self {
        case .png:
            return image.pngData()
        case .jpeg(let compressionQuality):
            return image.jpegData(compressionQuality: compressionQuality)
        }
    }

    /// File extension for the format.
    var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        }
    }
}
