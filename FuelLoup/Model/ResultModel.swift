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
    let address: Address?
    let position: Position
    let chargingPark: ChargingPark?
    let dataSources: DataSources?
}

struct Poi: Decodable {
    let name: String
    let phone: String?
    let url: String?
}

struct Position: Decodable {
    let lat: Double
    let lon: Double
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

// MARK: - Model for Transformable objects for fav station's CoreData model

public class Connector: NSObject, NSSecureCoding, Decodable {
    let connectorType: String
    let ratedPowerKW: Float
    let currentA: Int
    let currentType: String
    let voltageV: Int
    
    init(connectorType: String, ratedPowerKW: Float, currentA: Int, currentType: String, voltageV: Int) {
        self.connectorType = connectorType
        self.ratedPowerKW = ratedPowerKW
        self.currentA = currentA
        self.currentType = currentType
        self.voltageV = voltageV
    }
    
    public required init?(coder: NSCoder) {
        connectorType = coder.decodeObject(forKey: "connectorType") as? String ?? ""
        ratedPowerKW = coder.decodeFloat(forKey: "ratedPowerKW")
        currentA = coder.decodeInteger(forKey: "currentA")
        currentType = coder.decodeObject(forKey: "currentType") as? String ?? ""
        voltageV = coder.decodeInteger(forKey: "voltageV")
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(connectorType, forKey: "connectorType")
        coder.encode(ratedPowerKW, forKey: "ratedPowerKW")
        coder.encode(currentA, forKey: "currentA")
        coder.encode(currentType, forKey: "currentType")
        coder.encode(voltageV, forKey: "voltageV")
    }
    
    public static var supportsSecureCoding: Bool {
        true
    }
    
}

public class Address: NSObject, NSSecureCoding, Decodable {
    let streetNumber: String?
    let streetName: String?
    let municipality: String?
    let postalCode: String?
    let country: String?
    
    init(streetNumber: String?, streetName: String?, municipality: String?, postalCode: String?, country: String?) {
        self.streetNumber = streetNumber
        self.streetName = streetName
        self.municipality = municipality
        self.postalCode = postalCode
        self.country = country
    }
    
    public required init?(coder: NSCoder) {
        streetNumber = coder.decodeObject(forKey: "streetNumber") as? String
        streetName = coder.decodeObject(forKey: "streetName") as? String
        municipality = coder.decodeObject(forKey: "municipality") as? String
        postalCode = coder.decodeObject(forKey: "postalCode") as? String
        country = coder.decodeObject(forKey: "country") as? String
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(streetNumber, forKey: "streetNumber")
        coder.encode(streetName, forKey: "streetName")
        coder.encode(municipality, forKey: "municipality")
        coder.encode(postalCode, forKey: "postalCode")
        coder.encode(country, forKey: "country")
    }
    
    public static var supportsSecureCoding: Bool {
        true
    }
}

public class ChargingPark: NSObject, NSSecureCoding, Decodable {
    let connectors: [Connector]
    
    init(connectors:  [Connector]) {
        self.connectors = connectors
    }

    public required init?(coder: NSCoder) {
        connectors = coder.decodeObject(forKey: "connectors") as! [Connector]
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(connectors, forKey: "connectors")
    }
    
    public static var supportsSecureCoding: Bool {
        true
    }
}
