//
//  Asset+CoreDataProperties.swift
//  Nest
//
//  Created by Jim Wang on 2025/7/31.
//
//

import Foundation
import CoreData


extension Asset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
        return NSFetchRequest<Asset>(entityName: "Asset")
    }

    @NSManaged public var createdAt: Date!
    @NSManaged public var fileSize: Int64
    @NSManaged public var id: String!
    @NSManaged public var metadata: String?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var type: String!

}
