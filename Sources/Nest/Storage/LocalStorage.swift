//
//  LocalStorage.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import CryptoKit
import Foundation

public class LocalStorage: NestStorage {
    private let baseDirectory: URL

    /// Initializes the LocalStorage with a custom base URL.
    public init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    /// Convenience initializer for using standard iOS directories with an optional subfolder.
    public convenience init(directory: Directory, subfolder: String = "nest-local-storage") {
        var baseURL = directory.url
        baseURL = baseURL.appendingPathComponent(subfolder)
        self.init(baseDirectory: baseURL)
    }

    // MARK: - NestStorage Protocol Implementation

    public func write(data: Data, forAsset asset: NestAsset) async throws {
        let fileURL = makeFileURL(for: asset)
        let dirURL = fileURL.deletingLastPathComponent()
        try await Task.detached {
            do {
                let fileManager = FileManager.default
                // Ensure the directory exists
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
                
                // Write data to the file (overwrites if it exists)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                
                try data.write(to: fileURL)
            } catch {
                throw NestError.failedToWriteData(underlyingError: error)
            }
        }.value
    }

    public func readData(forAsset asset: NestAsset) async throws -> Data {
        guard await dataExists(forAsset: asset) else {
            throw NestError.dataNotFound
        }
        let fileURL = makeFileURL(for: asset)
        return try await Task.detached {
            do {
                return try Data(contentsOf: fileURL)
            } catch {
                throw NestError.failedToReadData(underlyingError: error)
            }
        }.value
    }

    public func deleteData(forAsset asset: NestAsset) async throws {
        guard await dataExists(forAsset: asset) else {
            throw NestError.dataNotFound
        }
        let fileURL = makeFileURL(for: asset)
        try await Task.detached {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                throw NestError.failedToDeleteData(underlyingError: error)
            }
        }.value
    }

    public func dataExists(forAsset asset: NestAsset) async -> Bool {
        let fileURL = makeFileURL(for: asset)
        return await Task.detached {
            return FileManager.default.fileExists(atPath: fileURL.path)
        }.value
    }

    public func deleteAll() async throws {
        let directoryURL = baseDirectory
        return try await Task.detached {
            do {
                try FileManager.default.removeItem(at: directoryURL)
            } catch {
                throw NestError.failedToDeleteData(underlyingError: error)
            }
        }.value
    }

    // MARK: - Helper Methods

    private func makeFileURL(for asset: NestAsset) -> URL {
        // To improve file system performance and avoid having too many files in a single directory,
        // we organize files into a hierarchical structure using two levels of subdirectories.
        // This approach prevents performance degradation when the number of files grows significantly.
        // Each level is derived from the MD5 hash of the asset ID to ensure consistent and evenly distributed paths.

        // Example mapping table for paths:
        //
        // Identifier         Asset Type    MD5 Hash        Path
        // ---------------------------------------------------------------------------
        // example-photo-id   photo         ab56b4d92b4...  /tmp/localStorage/photo/ab/56/example-photo
        // another-video-id   video         e99a18c428c...  /tmp/localStorage/video/e9/9a/another-video
        //

        // Target base directory, e.g., "/tmp/localStorage/photo"
        let typeDirectory = baseDirectory.appendingPathComponent(asset.type.folder)

        // Generate the MD5 hash of the localIdentifier
        let md5 = md5Hash(from: asset.id)

        // Use the first two characters as the first-level subdirectory
        let firstLevel = String(md5.prefix(2))
        // Use the next two characters as the second-level subdirectory
        let secondLevel = String(md5.dropFirst(2).prefix(2))

        // Combine the directory path
        let directoryPath = typeDirectory
            .appendingPathComponent(firstLevel)
            .appendingPathComponent(secondLevel)

        // Return the final file path with the asset ID as the file name
        return directoryPath.appendingPathComponent(asset.id)
    }

    /// Computes the MD5 hash of a given string and returns it as a hexadecimal string.
    private func md5Hash(from string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Helper

private extension NestAssetType {
    var folder: String {
        switch self {
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .document:
            return "document"
        case .audio:
            return "audio"
        case .custom:
            return "custom"
        }
    }
}
