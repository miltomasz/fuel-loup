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
    
    // MARK: - Actions
    
    func delete(_ station: ResultViewModel, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let idPredicate = NSPredicate(format: "id == %@", station.id)
        let favFetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
        favFetchRequest.predicate = idPredicate
        
        do {
            let toDeleteFavs = try viewContext.fetch(favFetchRequest)
            guard let favToDelete = toDeleteFavs.first else { return }
            
            viewContext.delete(favToDelete)
            try viewContext.save()
            completionHandler(.success(true))
        } catch {
            debugPrint("Could not delete favorite station from core data: \(error)")
            completionHandler(.failure(error))
        }
    }
    
    func save(_ station: ResultViewModel, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        let favStation = FavouriteStation(context: viewContext)
        favStation.id = station.result.id
        favStation.lat = station.result.position.lat
        favStation.lng = station.result.position.lon
        favStation.parks = station.result.chargingPark
        favStation.poiName = station.result.poi.name
        favStation.address = station.result.address
        favStation.poiPhone = station.result.poi.phone
        favStation.creationDate = Date()
        
        do {
            try viewContext.save()
            completionHandler(.success(true))
        } catch {
            debugPrint("Could not save favorite station to core data: \(error)")
            completionHandler(.failure(error))
        }
    }
    
}
