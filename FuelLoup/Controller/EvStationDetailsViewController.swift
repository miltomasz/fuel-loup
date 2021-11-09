//
//  EvStationDetailsViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 23/08/2021.
//

import UIKit

final class EvStationDetailsViewController: UIViewController {
    
    // MARK: - IB
    
    @IBOutlet weak var stationImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var basicInfoView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var phone: UILabel!
    
    // MARK: - Properties
    
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var chargingPark: ChargingPark?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        NetworkHelper.hideLoaderIfStopped(activityIndicator: activityIndicator)
        
        setupTitle()
        setupBasicInfo()
        setupConnectorsLabel()
        setupChargingPark()
        
        loadPhotoIfExists()
    }
    
    private func loadPhotoIfExists() {
        if let poiDetailsId = poiDetailsId {
            NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
            FuelLoupClient.getEvStationDetails(id: poiDetailsId, completion: handleStationDetailsResponse(details:error:))
        } else {
            stationImage.image = UIImage(named: "default-station-icon")
            stationImage.contentMode = .scaleAspectFill
        }
    }
    
    private func handleStationDetailsResponse(details: PoiDetails?, error: Error?) {
        guard let details = details else { return }
        
        if let photos = details.result.photos, photos.count > 0 {
            FuelLoupClient.getPhoto(id: photos[0].id, completion: handlePhotoResponse(image:error:))
        } else {
            NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        }
    }
    
    private func handlePhotoResponse(image: UIImage?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        guard let image = image else {
            stationImage.image = UIImage(named: "default-station-icon")
            stationImage.contentMode = .scaleAspectFill
            return
        }
        
        stationImage.image = image
    }
    
    // MARK: - Setup layout
    
    private func setupTitle() {
        if let nameArray = poi?.name.components(separatedBy: ","), nameArray.count > 1 {
            title = nameArray.first
        } else if let nameArray = poi?.name.components(separatedBy: " "), nameArray.count > 1 {
            title = nameArray.first
        } else {
            title = "Station"
        }
    }
    
    private func setupBasicInfo() {
        basicInfoView.layer.borderWidth = 0.5
        basicInfoView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        basicInfoView.layer.cornerRadius = 10
        
        labelText(for: name, label: nameLabel, text: poi?.name)
        labelText(for: phone, label: phoneLabel, text: poi?.phone)
    }
    
    private func setupConnectorsLabel() {
        let connectorsLabel = UILabel()
        connectorsLabel.text = "Connectors"
        connectorsLabel.textAlignment = .left
        connectorsLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        connectorsLabel.textColor = .black
        
        connectorsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectorsLabel.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        
        contentStackView.addArrangedSubview(connectorsLabel)
    }
    
    private func labelText(for name: UILabel, label: UILabel, text: String?) {
        if let name = text {
            label.text = name
        } else {
            name.isHidden = true
            label.isHidden = true
        }
    }
    
    private func setupChargingPark() {
        chargingPark?.connectors.forEach { connector in
            let connectorView = ConnectorView()
            connectorView.typeValueLabel.text = connector.connectorType
            connectorView.powerValueLabel.text = "\(connector.ratedPowerKW)"
            
            contentStackView.addArrangedSubview(connectorView)
        }
    }
    
}
