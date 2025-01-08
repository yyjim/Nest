//
//  LocalStorage.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import CryptoKit
import Foundation

@globalActor actor LocalStorageFileManagerActor: GlobalActor {
    static let shared = LocalStorageFileManagerActor()
}

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

    @LocalStorageFileManagerActor
    public func write(data: Data, assetIdentifier: String) async throws {
        let fileURL = makeFileURL(assetIdentifier: assetIdentifier)
        let dirURL = fileURL.deletingLastPathComponent()
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
    }

    @LocalStorageFileManagerActor
    public func readData(assetIdentifier: String) async throws -> Data {
        guard await dataExists(assetIdentifier: assetIdentifier) else {
            throw NestError.dataNotFound
        }
        let fileURL = makeFileURL(assetIdentifier: assetIdentifier)
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw NestError.failedToReadData(underlyingError: error)
        }
    }

    @LocalStorageFileManagerActor
    public func deleteData(assetIdentifier: String) async throws {
        do {
            let fileURL = makeFileURL(assetIdentifier: assetIdentifier)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            throw NestError.failedToDeleteData(underlyingError: error)
        }
    }

    @LocalStorageFileManagerActor
    public func dataExists(assetIdentifier: String) async -> Bool {
        let fileURL = makeFileURL(assetIdentifier: assetIdentifier)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    @LocalStorageFileManagerActor
    public func deleteAll() async throws {
        let directoryURL = baseDirectory
        do {
            if FileManager.default.fileExists(atPath: directoryURL.path) {
                try FileManager.default.removeItem(at: directoryURL)
            }
        } catch {
            throw NestError.failedToDeleteData(underlyingError: error)
        }
    }

    // MARK: - Helper Methods

    private func makeFileURL(assetIdentifier: String) -> URL {
        // To improve file system performance and avoid having too many files in a single directory,
        // we organize files into a hierarchical structure using two levels of subdirectories.
        // This approach prevents performance degradation when the number of files grows significantly.
        // Each level is derived from the MD5 hash of the asset ID to ensure consistent and evenly distributed paths.

        // Example mapping table for paths:
        //
        // Identifier         Asset Type    MD5 Hash        Path
        // ---------------------------------------------------------------------------
        // example-photo-id   photo         ab56b4d92b4...  /tmp/localStorage/ab/56/example-photo
        // another-video-id   video         e99a18c428c...  /tmp/localStorage/e9/9a/another-video
        //

        // Generate the MD5 hash of the localIdentifier
        let md5 = md5Hash(from: assetIdentifier)

        // Use the first two characters as the first-level subdirectory
        let firstLevel = String(md5.prefix(2))
        // Use the next two characters as the second-level subdirectory
        let secondLevel = String(md5.dropFirst(2).prefix(2))

        // Combine the directory path
        let directoryPath = baseDirectory
            .appendingPathComponent(firstLevel)
            .appendingPathComponent(secondLevel)

        // Return the final file path with the asset ID as the file name
        return directoryPath.appendingPathComponent(assetIdentifier)
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
