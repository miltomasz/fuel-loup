//
//  JsonDataToChargingParkTransformer.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 14/01/2022.
//

import Foundation
import CoreData

class JsonDataToChargingParkTransformer: ValueTransformer {

    override class func transformedValueClass() -> AnyClass {
        return ChargingPark.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let charginPark = value as? ChargingPark else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: charginPark, requiringSecureCoding: true)
            return data
        } catch {
            assertionFailure("Failed to transform `CharginPark` to `Data`")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: ChargingPark.self, from: data as Data)
            return color
        } catch {
            assertionFailure("Failed to transform `Data` to `CharginPark`")
            return nil
        }
    }
    
}
