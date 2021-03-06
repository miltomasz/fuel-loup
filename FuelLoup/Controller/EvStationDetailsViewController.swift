//
//  EvStationDetailsViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 23/08/2021.
//

import UIKit
import Lottie
import CoreData
import MapKit

protocol TableViewRefreshDelegate: AnyObject {
    func refreshTable()
}

final class EvStationDetailsViewController: UIViewController {
    
    // MARK: - Configuration
    
    private enum Configuration {
        static let defaultStationImage = UIImage(named: "default-station-icon")
    }
    
    // MARK: - IB
    
    @IBOutlet weak var driveToStationButton: UIButton!
    @IBOutlet weak var stationImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var basicInfoView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var addToFavouritesButton: UIButton!
    @IBOutlet weak var contentStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentStackViewTrailingConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    private var addFavoritesButtonConfiguration: AddFavoritesButtonConfiguration = .notAdded
    private var animationView: AnimationView = .init(name: "added_fav")
    private var _dataController: FuelLoupDataController?
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var chargingPark: ChargingPark?
    var selectedEvStation: ResultViewModel?
    var dataController: FuelLoupDataController? {
        set {
            _dataController = newValue
        }
        get {
            return _dataController
        }
    }
    weak var tableViewRefreshDelegate: TableViewRefreshDelegate?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        NetworkHelper.hideLoaderIfStopped(activityIndicator: activityIndicator)
        
        setupTitle()
        setupBasicInfo()
        setupConnectorsLabel()
        setupAddFavAnimationView()
        loadPhotoIfExists()
        loadAddToFavoritesButtonStatus()
        loadAvailability()
        setupAddFavoritesButton()
    }
    
    private func loadAvailability() {
        if let chargingAvailabilityId = chargingAvailabilityId {
            NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
            FuelLoupClient.getChargingStationAvailability(availabilityId: chargingAvailabilityId, completion: handleAvailabilityResponse(availability:error:))
        } else {
            NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
            setupChargingPark()
        }
    }
    
    private func handleAvailabilityResponse(availability: ChargingStationAvailability?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        guard
            let availability = availability,
                availability.connectors.count > 0,
            let powerLevel = availability.connectors.first,
                powerLevel.hasPowerLevels else {
                setupChargingPark()
                return
            }
        
        availability.connectors.forEach { connector in
            let connectorView = ConnectorView()
            connectorView.typeValueLabel.text = prepareType(for: connector.type ?? "")
            let powerLevelInfo = connector.perPowerLevel?.compactMap { $0.info }
            connectorView.powerValueLabel.text = powerLevelInfo?.joined(separator: " ")
            
            contentStackView.insertArrangedSubview(connectorView, at: 3)
        }
    }
    
    private func loadPhotoIfExists() {
        if let poiDetailsId = poiDetailsId {
            NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
            FuelLoupClient.getEvStationDetails(id: poiDetailsId, completion: handleStationDetailsResponse(details:error:))
        } else {
            setupDefaultStationImage()
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
        
        if let image = image {
            stationImage.image = image
        } else {
            setupDefaultStationImage()
        }
    }
    
    // MARK: - Setup layout
    
    private func setupTitle() {
        title = EvStationHelper.extractStationName(from: poi)
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
        connectorsLabel.text = "details.connectors".localized
        connectorsLabel.textAlignment = .left
        connectorsLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        connectorsLabel.textColor = .black
        
        connectorsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectorsLabel.heightAnchor.constraint(equalToConstant: 40.0)
        ])
        
        contentStackView.insertArrangedSubview(connectorsLabel, at: 2)
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
            connectorView.typeValueLabel.text = prepareType(for: connector.connectorType)
            connectorView.powerValueLabel.text = "\(connector.ratedPowerKW)"
            
            contentStackView.insertArrangedSubview(connectorView, at: 3)
        }
    }
    
    private func prepareType(for connectorType: String) -> String {
        var types: Array = connectorType.components(separatedBy: "Type2")
        guard types.count > 0 else { return connectorType }
        
        types.append("Type2")
        return types.joined(separator: ", ")
    }
    
    private func setupAddFavAnimationView() {
        animationView.isHidden = true
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.animationSpeed = 1
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        stationImage.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: stationImage.topAnchor),
            animationView.trailingAnchor.constraint(equalTo: stationImage.trailingAnchor),
            animationView.heightAnchor.constraint(equalToConstant: 50.0),
            animationView.widthAnchor.constraint(equalToConstant: 50.0)
        ])
    }
    
    private func setupDefaultStationImage() {
        stationImage.image = Configuration.defaultStationImage
        stationImage.contentMode = .scaleAspectFit
    }
    
    private func setupAddFavoritesButton() {
        addToFavouritesButton.setTitle(addFavoritesButtonConfiguration.title, for: .normal)
        addToFavouritesButton.backgroundColor = addFavoritesButtonConfiguration.color
        addToFavouritesButton.setTitleColor(addFavoritesButtonConfiguration.titleColor, for: .normal)
    }
    
    // MARK: - Load data from Core Data
    
    private func loadAddToFavoritesButtonStatus() {
        guard let dataController = dataController, let selectedEvStationId = selectedEvStation?.id else { return }
        
        let idPredicate = NSPredicate(format: "id == %@", selectedEvStationId)
        let favFetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
        favFetchRequest.predicate = idPredicate
        
        do {
            let evStationFavorites = try dataController.viewContext.fetch(favFetchRequest)
            addFavoritesButtonConfiguration = evStationFavorites.first == nil ? .notAdded : .added
        } catch {
            debugPrint("Could not load favorite station: \(error)")
        }
    }

}

// MARK: - Actions

extension EvStationDetailsViewController {
    
    // MARK: - Configuration
    
    private enum AnimationConfiguration {
        static let showDelay = 0.0
        static let hideDelay = 2.0
    }
    
    @IBAction func driveToStation(_ button: UIButton) {
        guard let selectedEvStation = self.selectedEvStation else { return }
        
        let latitude = selectedEvStation.result.position.lat
        let longitude = selectedEvStation.result.position.lon
        let url = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving&zoom=14&views=traffic")
        
        if let googleMapUrl = url, UIApplication.shared.canOpenURL(googleMapUrl) {
            let actionSheet = UIAlertController(title: "Open Location", message: "Choose an app to open direction", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Google Maps", style: .default, handler: { _ in
                UIApplication.shared.open(googleMapUrl, options: [:], completionHandler: nil)
            }))
            actionSheet.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { _ in
                let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
                mapItem.name = "Destination"
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            }))
            
            actionSheet.popoverPresentationController?.sourceView = driveToStationButton
            actionSheet.popoverPresentationController?.sourceRect = driveToStationButton.bounds
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true, completion: nil)
        } else {
            let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = "Destination"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    @IBAction func onAddToFavouritesTap(_ button: UIButton) {
        guard let dataController = dataController, let selectedEvStation = selectedEvStation else { return }
        
        switch addFavoritesButtonConfiguration {
        case .added:
            dataController.delete(selectedEvStation) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.addFavoritesButtonConfiguration = .notAdded
                    self.setupAddFavoritesButton()
                case .failure:
                    NetworkHelper.showFailurePopup(title: "Error", message: "Could not delete favorite station", on: self)
                }
            }
        case .notAdded:
            dataController.save(selectedEvStation) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.perform(#selector(self.showAddFavAnimation), with: self, afterDelay: AnimationConfiguration.showDelay)
                    self.addFavoritesButtonConfiguration = .added
                    self.setupAddFavoritesButton()
                case .failure(let error):
                    let message = "Could not save favorite station to core data: \(error)"
                    NetworkHelper.showFailurePopup(title: "Error", message: message, on: self)
                }
            }
        }
        tableViewRefreshDelegate?.refreshTable()
    }
    
    @objc private func showAddFavAnimation(_ sender: Any) {
        animationView.isHidden = false
        animationView.play()
        perform(#selector(self.hideAddFavAnimation), with: self, afterDelay: AnimationConfiguration.hideDelay)
    }
    
    @objc private func hideAddFavAnimation(_ sender: Any) {
        animationView.isHidden = true
    }
    
}
