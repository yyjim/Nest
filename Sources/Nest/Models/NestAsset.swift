//
//  NestAsset.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation

public typealias NEAsset = NestAsset

public enum MetadataValue: Sendable, Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([MetadataValue])
    case dictionary([String: MetadataValue])
}

public struct NestAsset: Sendable, Equatable {
    public let id: String
    public let type: NestAssetType
    public let createdAt: Date
    public var modifiedAt: Date?
    public var fileSize: Int?
    public var metadata: [String: MetadataValue]?

    // Custom URI scheme
    private static let uriScheme = "nest-asset"

    // Computed property to get a valid URI for this asset
    public var assetURL: URL {
        URL(string: "\(Self.uriScheme):/\(id)")!
    }

    // Initializer
    public init(
        id: String = UUID().uuidString,
        type: NestAssetType,
        createdAt: Date = .now,
        modifiedAt: Date? = nil,
        fileSize: Int? = nil,
        metadata: [String: MetadataValue]? = nil
    ) {
        self.id = id
        self.type = type
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.fileSize = fileSize
        self.metadata = metadata
    }

    // Validate if a given URI matches the nest-asset scheme
    public static func isValidURI(_ uri: URL) -> Bool {
        uri.scheme == uriScheme
    }

    // Retrieve the identifier (id) from a given URI
    public static func identifier(from uri: URL) -> String? {
        guard isValidURI(uri) else { return nil }
        // Remove the first "/" from the path
        return String(uri.path.dropFirst())
    }
}
