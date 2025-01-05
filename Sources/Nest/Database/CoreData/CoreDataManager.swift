//
//  CoreDataManager.swift
//  Nest
//
//  Created by Jim Wang on 2025/1/5.
//

import CoreData

struct CoreDataManager {
    // Singleton instance
    static let shared = CoreDataManager()

    // The Core Data persistent container
    private let persistentContainer: NSPersistentContainer

    // The main managed object context
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

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

    /// Saves any changes in the context to the persistent store.
    /// - Throws: An error if saving fails.
    public func saveContext() throws {
        guard context.hasChanges else {
            return
        }
        try context.save()
    }
}
