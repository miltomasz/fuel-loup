//
//  FuelLoupDataController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 07/01/2022.
//

import Foundation
import CoreData

final class FuelLoupDataController {
    
    // MARK: Dependencies
    
    private let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: Initialization
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else { fatalError(error!.localizedDescription) }
            
            completion?()
        }
    }
}
