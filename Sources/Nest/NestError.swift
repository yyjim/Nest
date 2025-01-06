//
//  NestError.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/4.
//

import Foundation

public enum NestError: Error, Equatable, LocalizedError {
    case invalidAssetURL
    case invalidImageFormat
    case invalidAssetType
    case unableToConvertToData
    case assetNotFound
    case dataNotFound
    case unknownError
    case failedToWriteData(underlyingError: Error?)
    case failedToReadData(underlyingError: Error?)
    case failedToDeleteData(underlyingError: Error)

    // Description for each error case
    public var errorDescription: String? {
        switch self {
        case .invalidAssetURL:
            return "The asset's URL is invalid or cannot be processed."
        case .unableToConvertToData:
            return "Failed to convert the input into valid data."
        case .assetNotFound:
            return "The requested asset could not be found."
        case .dataNotFound:
            return "The requested data could not be found in storage."
        case .failedToWriteData:
            return "Failed to write data to storage."
        case .failedToReadData:
            return "Failed to read data from storage."
        case .failedToDeleteData(let underlyingError):
            return "Failed to delete data from storage. Underlying error: \(underlyingError.localizedDescription)"
        case .invalidImageFormat:
            return "The image format is invalid or unsupported."
        case .invalidAssetType:
            return "The asset type is invalid or unsupported."
        case .unknownError:
            return "An unknown error occurred."
        }
    }

    // Implementing Equatable for cases with associated values
    public static func == (lhs: NestError, rhs: NestError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAssetURL, .invalidAssetURL),
            (.invalidImageFormat, .invalidImageFormat),
            (.invalidAssetType, .invalidAssetType),
            (.unableToConvertToData, .unableToConvertToData),
            (.assetNotFound, .assetNotFound),
            (.dataNotFound, .dataNotFound),
            (.unknownError, .unknownError):
            return true

        case let (.failedToWriteData(lhsError), .failedToWriteData(rhsError)):
            return areErrorsEqual(lhsError, rhsError)

        case let (.failedToReadData(lhsError), .failedToReadData(rhsError)):
            return areErrorsEqual(lhsError, rhsError)

        case let (.failedToDeleteData(lhsError), .failedToDeleteData(rhsError)):
            return type(of: lhsError) == type(of: rhsError) &&
            lhsError.localizedDescription == rhsError.localizedDescription

        default:
            return false
        }
    }

    // Helper function to compare optional errors
    private static func areErrorsEqual(_ lhs: Error?, _ rhs: Error?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return type(of: lhs) == type(of: rhs) &&
            lhs.localizedDescription == rhs.localizedDescription
        default:
            return false
        }
    }
}
