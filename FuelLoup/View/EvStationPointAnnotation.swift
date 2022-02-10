//
//  EvStationPointAnnotation.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 02/09/2021.
//

import MapKit

class EvStationPointAnnotation: MKPointAnnotation {
    var selectedEvStationId: String?
    var dataSources: DataSources?
    var position: Position?
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var chargingPark: ChargingPark?
}
