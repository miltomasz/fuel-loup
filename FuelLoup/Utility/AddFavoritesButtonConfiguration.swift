//
//  AddFavoritesButtonConfiguration.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/02/2022.
//

import UIKit

enum AddFavoritesButtonConfiguration {
    case added
    case notAdded
    
    var titleColor: UIColor {
        switch self {
        case .added:
            return UIColor.systemPurple
        case .notAdded:
            return UIColor.white
        }
    }
    
    var color: UIColor {
        switch self {
        case .added:
            return UIColor.systemGray4
        case .notAdded:
            return UIColor.systemYellow
        }
    }
    
    var title: String {
        switch self {
        case .added:
            return "Remove from favorites"
        case .notAdded:
            return "Add to favorites"
        }
    }
    
}
