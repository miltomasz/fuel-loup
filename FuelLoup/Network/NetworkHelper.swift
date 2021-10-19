//
//  NetworkHelper.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import UIKit

enum DisplayViewControllerShowType {
    case fullScreen
    case modally
}

class NetworkHelper {
    
    private init() {}
    
    static func hideLoaderIfStopped(activityIndicator: UIActivityIndicatorView) {
        activityIndicator.hidesWhenStopped = true
    }
    
    static func showLoader(_ show: Bool, activityIndicator: UIActivityIndicatorView) {
        if show {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
    
    static func showFailurePopup(title: String, message: String, show: DisplayViewControllerShowType = .fullScreen, on viewController: UIViewController) {
        let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        switch show {
        case .fullScreen:
            viewController.show(alertViewController, sender: nil)
        case .modally:
            DispatchQueue.main.async {
                viewController.present(alertViewController, animated: true, completion: nil)
            }
        }
    }
    
}

