//
//  EvStationHelper.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 17/11/2021.
//

import Foundation

final class EvStationHelper {
    
    private init() {}
    
    class func extractStationName(from poi: Poi?) -> String {
        var title: String?
        if let nameArray = poi?.name.components(separatedBy: ","), nameArray.count > 1 {
            title = nameArray.first
        } else if let nameArray = poi?.name.components(separatedBy: " "), nameArray.count > 1 {
            title = nameArray.first
        }
        return title ?? "Station"
    }
}
