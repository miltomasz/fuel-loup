//
//  DetailsModel.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 22/08/2021.
//

import Foundation

struct ChargingStationAvailability: Decodable {
    let chargingAvailability: String
    let connectors: [ChargingAvailabilityConnector]
}

struct ChargingAvailabilityConnector: Decodable {
    let type: String?
    let perPowerLevel: [PerPowerLevel]?
    
    var hasPowerLevels: Bool {
        if let perPowerLevel = perPowerLevel, !perPowerLevel.isEmpty {
            return true
        }
        return false
    }
}

struct PerPowerLevel: Decodable {
    let powerKW: Double
    let available: Bool
    let outOfService: Bool
    
    var info: String {
        let availableIcon = available ? "\u{1F7E2}" : "\u{1F534}"
        return "\(powerKW)" + availableIcon
    }
}

struct PoiDetails: Decodable {
    let id: String
    let result: DetailResult
}

struct DetailResult: Decodable {
    let description: String?
    let rating: Rating
    let priceRange: PriceRange
    let photos: [Photo]?
}

struct Rating: Decodable {
    let totalRatings: Int
    let value: Double
}

struct PriceRange: Decodable {
    let label: String?
    let value: Int?
}

struct Photo: Decodable {
    let id: String
}
