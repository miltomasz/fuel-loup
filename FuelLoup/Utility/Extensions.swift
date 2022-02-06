//
//  Extensions.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 30/01/2022.
//

import UIKit

extension UITableView {
    func removeExtraCellLines() {
        tableFooterView = UIView(frame: .zero)
    }
}
