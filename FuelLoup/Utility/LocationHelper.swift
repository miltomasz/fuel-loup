//
//  LocationHelper.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 24/11/2021.
//

import CoreLocation

struct LocationHelper {
    
    static var distanceSorting: ((CLLocation, ResultModel, ResultModel) throws -> Bool) = { currentLocation, res1, res2 in
        let loc1 = CLLocation(latitude: res1.position.lat, longitude: res1.position.lon)
        let loc2 = CLLocation(latitude: res2.position.lat, longitude: res2.position.lon)
        
        let distance1 = currentLocation.distance(from: loc1)
        let distance2 = currentLocation.distance(from: loc2)
        
        return distance2 > distance1
    }
    
}
