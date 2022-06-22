//
//  Utility+String.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 23/06/2022.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
