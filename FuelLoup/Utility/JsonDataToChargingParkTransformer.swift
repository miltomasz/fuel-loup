//
//  JsonDataToChargingParkTransformer.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 14/01/2022.
//

import Foundation
import CoreData

final class JsonDataToChargingParkTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func transformedValueClass() -> AnyClass {
        return ChargingPark.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [ChargingPark.self]
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let charginPark = value as? ChargingPark else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: charginPark, requiringSecureCoding: true)
            return data
        } catch {
            assertionFailure("Failed to transform `ChargingPark` to `Data`")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        
        do {
            let chargingPark = try NSKeyedUnarchiver.unarchivedObject(ofClass: ChargingPark.self, from: data as Data)
            return chargingPark
        } catch {
            assertionFailure("Failed to transform `Data` to `ChargingPark`")
            return nil
        }
    }
    
}
