//
//  ResultViewModel.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 28/11/2021.
//

import CoreLocation

struct ResultViewModel {
    
    private enum Configuration {
        static var kilometers = "km"
    }
    
    var id: String {
        result.id
    }
    
    let result: Result
    var currentLocation: CLLocation?
    
    var distance: String {
        guard let currentLocation = currentLocation else { return "" }
        
        let location = CLLocation(latitude: result.position.lat, longitude: result.position.lon)
        let distance = currentLocation.distance(from: location)
        let rounded = String(format: "%.2f", distance / 1000)
        
        return "\(rounded) \(Configuration.kilometers)"
    }
    
}
