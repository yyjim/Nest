//
//  CoreDataManager.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import CoreData

struct CoreDataManager {
    static let shared = CoreDataManager()

    // The Core Data persistent container
    let persistentContainer: NSPersistentContainer

    /// Initializes the Core Data manager with a specific model name.
    /// - Parameter modelName: The name of the Core Data model file.
    private init(modelName: String = "NestCoreDataModel") {
        // Initialize the persistent container
        let modelURL = Bundle.module.url(forResource: modelName, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        persistentContainer.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        // Configure context merge policies
        persistentContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
}
