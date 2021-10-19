//
//  Result.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 03/08/2021.
//

import Foundation

struct Result: Decodable {
    
    let id: String
    let poi: Poi
    let address: Address
    let position: Position
    let chargingPark: ChargingPark
    let dataSources: DataSources
    
}

struct Poi: Decodable {
    
    let name: String
    let phone: String?
    let url: String?
    
}

struct Address: Decodable {
    
    let streetNumber: String?
    let streetName: String?
    let municipality: String?
    let postalCode: String
    let country: String

}

struct Position: Decodable {
    
    let lat: Double
    let lon: Double
    
}

struct ChargingPark: Decodable {
    
    let connectors: [Connector]
    
}

struct Connector: Decodable {
    
    let connectorType: String
    let ratedPowerKW: Float
    let currentA: Int
    let currentType: String
    let voltageV: Int
    
}

struct DataSources: Decodable {
    
    let chargingAvailability: ChargingAvailability
    let poiDetails: [PoiDetail]?
    
}

struct ChargingAvailability: Decodable {
    
    let id: String
    
}

struct PoiDetail: Decodable {
    
    let id: String
    
}
