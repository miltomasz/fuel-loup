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
    
    let result: Result
    let currentLocation: CLLocation
    
    var distance: String {
        let location = CLLocation(latitude: result.position.lat, longitude: result.position.lon)
        let distance = currentLocation.distance(from: location)
        let rounded = String(format: "%.2f", distance / 1000)
        
        return "\(rounded) \(Configuration.kilometers)"
    }
    
}
