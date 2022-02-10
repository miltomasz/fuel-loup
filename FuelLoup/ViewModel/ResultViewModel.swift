//
//  ResultViewModel.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 28/11/2021.
//

import CoreLocation

struct ResultViewModel {
    
    // MARK: - Configuration
    
    private enum Configuration {
        static var kilometers = "km"
    }
    
    // MARK: - Properties
    
    let result: ResultModel
    var currentLocation: CLLocation?
    
    var id: String {
        return result.id
    }
    
    var distance: String {
        guard let currentLocation = currentLocation else { return "" }
        
        let location = CLLocation(latitude: result.position.lat, longitude: result.position.lon)
        let distance = currentLocation.distance(from: location)
        let rounded = String(format: "%.2f", distance / 1000)
        
        return "\(rounded) \(Configuration.kilometers)"
    }
    
    static func create(from selectedEvStationId: String, chargingPark: ChargingPark?, position: Position?, poi: Poi?, dataSources: DataSources?) -> Self? {
        guard let poi = poi, let position = position else { return nil }
        
        let resultModel = ResultModel(id: selectedEvStationId, poi: poi, address: nil, position: position, chargingPark: chargingPark, dataSources: dataSources)
        
        return ResultViewModel(result: resultModel, currentLocation: CLLocation(latitude: position.lat, longitude: position.lon))
    }
    
}
