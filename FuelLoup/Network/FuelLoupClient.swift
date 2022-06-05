//
//  FuelLoupClient.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import UIKit
import Alamofire

struct FuelLoupClient {
    struct Auth {
        static let ttKey = ""
    }
    
    struct RequestParam {
        static let area = 5000
        static let categorySet = 7309
    }
    
    enum Endpoints {
        static let baseSearchUrl = "https://api.tomtom.com/search/2/nearbySearch/.json"
        static let poiDetailsUrl = "https://api.tomtom.com/search/2/poiDetails.json"
        static let photoUrl = "https://api.tomtom.com/search/2/poiPhoto"
        static let chargingStationAvailabilityUrl = "https://api.tomtom.com/search/2/chargingAvailability.json"
        
        case getNearestEvStations(latitude: Double, longitude: Double)
        case getEvStationDetails(id: String)
        case getPhoto(id: String)
        case getAvailability(availabilityId: String)
        
        var stringValue: String {
            switch self {
            case let .getNearestEvStations(latitude, longitude):
                return Endpoints.baseSearchUrl + "?key=\(Auth.ttKey)&lat=\(latitude)&lon=\(longitude)&radius=\(RequestParam.area)&categorySet=\(RequestParam.categorySet)"
            case .getEvStationDetails(let id):
                return Endpoints.poiDetailsUrl + "?key=\(Auth.ttKey)&id=\(id)"
            case .getPhoto(id: let id):
                return Endpoints.photoUrl + "?key=\(Auth.ttKey)&id=\(id)"
            case .getAvailability(let availabilityId):
                return Endpoints.chargingStationAvailabilityUrl + "?key=\(Auth.ttKey)&chargingAvailability=\(availabilityId)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    static func getNearestEvStations(latitude: Double, longitude: Double, completion: @escaping ([ResultModel]?, Error?) -> Void) {
        AF.request(Endpoints.getNearestEvStations(latitude: latitude, longitude: longitude).url) { request in
            request.timeoutInterval = 20
        }
        .responseDecodable(of: StationsResponse.self) { response in
            if let responseValue = response.value {
                completion(responseValue.results, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    static func getEvStationDetails(id: String, completion: @escaping (PoiDetails?, Error?) -> Void) {
        AF.request(Endpoints.getEvStationDetails(id: id).url) { request in
            request.timeoutInterval = 20
        }
        .responseDecodable(of: PoiDetails.self) { response in
            if let poiDetails = response.value {
                completion(poiDetails, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    static func getPhoto(id: String, completion: @escaping (UIImage?, Error?) -> Void) {
        AF.request(Endpoints.getPhoto(id: id).url) { request in
            request.timeoutInterval = 20
        }
        .response { response in
            if let data = response.value as? Data {
                let image = UIImage(data: data)
                completion(image, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    static func getChargingStationAvailability(availabilityId: String, completion: @escaping (ChargingStationAvailability?, Error?) -> Void) {
        AF.request(Endpoints.getAvailability(availabilityId: availabilityId).url) { request in
            request.timeoutInterval = 20
        }
        .responseDecodable(of: ChargingStationAvailability.self) { response in
            if let stationAvailability = response.value {
                completion(stationAvailability, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
}
