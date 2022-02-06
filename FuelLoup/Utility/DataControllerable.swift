//
//  DataControllerable.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 22/01/2022.
//

import Foundation
import CoreData

protocol DataControllerable {
    var dataController: FuelLoupDataController? { set get }
}
