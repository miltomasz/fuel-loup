//
//  FuelLoupClient.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import UIKit
import Alamofire

class FuelLoupClient {
    
    struct Auth {
//        static let appId = "z9eDMHGTdyTTMMwYLwc0"
//        static let appCode = "KgGb4o4LljrLasCUP6yoSdOo2QuSwePrWxK_4K7kU5A"
//        static let apiKey = "_FQo20g38S_PxdtNSklfFgLkwAvKYfUuWTyE-wa4zHSs2fOyzvKMMGyQMKlqhcm9LoykYYSlbu4d_7kNylD8VA"
//        static let nrelApiKey = "yelsLDkSYHnqE3eXVt6Fg9PnoyREeha5PYYeeGds"
        static let ttKey = "OF0ZWUvDw0I9vxvagdwiRmEaWAxg1TAg"
    }
    
    struct RequestParam {
        static let area = 5000
        static let categorySet = 7309
    }
    
    enum Endpoints {
        static let baseSearchUrl = "https://api.tomtom.com/search/2/nearbySearch/.json"
        static let poiDetailsUrl = "https://api.tomtom.com/search/2/poiDetails.json"
        static let photoUrl = "https://api.tomtom.com/search/2/poiPhoto"
        
        case getNearestEvStations(latitude: Double, longitude: Double)
        case getEvStationDetails(id: String)
        case getPhoto(id: String)
        
        var stringValue: String {
            switch self {
            case let .getNearestEvStations(latitude, longitude):
                return Endpoints.baseSearchUrl + "?key=\(Auth.ttKey)&lat=\(latitude)&lon=\(longitude)&radius=\(RequestParam.area)&categorySet=\(RequestParam.categorySet)"
            case .getEvStationDetails(let id):
                return Endpoints.poiDetailsUrl + "?key=\(Auth.ttKey)&id=\(id)"
            case .getPhoto(id: let id):
                return Endpoints.photoUrl + "?key=\(Auth.ttKey)&id=\(id)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getNearestEvStations(latitude: Double, longitude: Double, completion: @escaping ([ResultModel]?, Error?) -> Void) {
        AF.request(Endpoints.getNearestEvStations(latitude: latitude, longitude: longitude).url)
            .responseDecodable(of: StationsResponse.self) { response in
                if let responseValue = response.value {
                    completion(responseValue.results, nil)
                } else {
                    completion(nil, response.error)
                }
            }
    }
    
    class func getEvStationDetails(id: String, completion: @escaping (PoiDetails?, Error?) -> Void) {
        AF.request(Endpoints.getEvStationDetails(id: id).url).responseDecodable(of: PoiDetails.self) { response in
            if let poiDetails = response.value {
                completion(poiDetails, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    class func getPhoto(id: String, completion: @escaping (UIImage?, Error?) -> Void) {
        AF.request(Endpoints.getPhoto(id: id).url).response { response in
            if let data = response.value as? Data {
                let image = UIImage(data: data)
                completion(image, nil)
            } else {
                completion(nil, response.error)
            }
        }
    }
    
    class func getChargingStationAvailability() {
        
    }
    
}
