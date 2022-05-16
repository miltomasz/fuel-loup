//
//  MapSettingsViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/05/2022.
//

import UIKit

protocol MapOverlayViewDelegate {
    func refreshMapView()
}

class MapSettingsViewController: UIViewController {
    
    // MARK: - Configuration
    
    private enum Configuration {
        static let blackWhiteMap = "BlackWhiteMap"
    }
    
    var delegate: MapOverlayViewDelegate?
    
    // MARK: - IB
    
    @IBOutlet weak var changeMapSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blackWhiteMapOn = UserDefaults.standard.bool(forKey: Configuration.blackWhiteMap)
        changeMapSwitch.isOn = blackWhiteMapOn
    }
    
    @IBAction func onMapChange(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(true, forKey: Configuration.blackWhiteMap)
        } else {
            UserDefaults.standard.set(false, forKey: Configuration.blackWhiteMap)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate?.refreshMapView()
    }
    
}
