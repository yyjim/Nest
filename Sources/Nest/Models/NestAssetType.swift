//
//  NestAssetType.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

public typealias NEAssetType = NestAssetType

public enum NestAssetType: Equatable, Sendable {
    case photo
    case video
    case document
    case audio
    case custom(String)

    /// Initializes a `NestAssetType` from a string value.
    /// - Parameter stringValue: The string representation of the asset type.
    init(stringValue: String) {
        switch stringValue.lowercased() {
        case "photo":
            self = .photo
        case "video":
            self = .video
        case "document":
            self = .document
        case "audio":
            self = .audio
        default:
            self = stringValue.isEmpty ? .document : .custom(stringValue)
        }
    }
}

extension NestAssetType {
    var stringValue: String {
        switch self {
        case .photo:
            return "photo"
        case .video:
            return "video"
        case .document:
            return "document"
        case .audio:
            return "audio"
        case .custom(let value):
            return value
        }
    }
}
