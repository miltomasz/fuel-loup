//
//  JsonDataToAddressTransformer.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 30/01/2022.
//

import Foundation
import CoreData

final class JsonDataToAddressTransformer: NSSecureUnarchiveFromDataTransformer {

    override class func transformedValueClass() -> AnyClass {
        return Address.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class var allowedTopLevelClasses: [AnyClass] {
        return [Address.self]
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let address = value as? Address else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: address, requiringSecureCoding: true)
            return data
        } catch {
            assertionFailure("Failed to transform `Address` to `Data`")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }
        
        do {
            let address = try NSKeyedUnarchiver.unarchivedObject(ofClass: Address.self, from: data as Data)
            return address
        } catch {
            assertionFailure("Failed to transform `Data` to `Address`")
            return nil
        }
    }

}
