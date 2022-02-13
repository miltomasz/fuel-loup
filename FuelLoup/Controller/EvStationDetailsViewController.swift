//
//  EvStationDetailsViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 23/08/2021.
//

import UIKit
import Lottie
import CoreData

protocol TableViewRefreshDelegate: AnyObject {
    func refreshTable()
}

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
    @IBOutlet weak var addToFavouritesButton: UIButton!
    @IBOutlet weak var contentStackViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentStackViewTrailingConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    private var addFavoritesButtonConfiguration: AddFavoritesButtonConfiguration = .notAdded
    private var animationView: AnimationView?
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
        setupChargingPark()
        setupAddFavAnimationView()
        loadPhotoIfExists()
        loadAddToFavoritesButtonStatus()
        setupAddFavoritesButton()
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
        connectorsLabel.text = "Connectors"
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
            connectorView.typeValueLabel.text = connector.connectorType
            connectorView.powerValueLabel.text = "\(connector.ratedPowerKW)"
            
            contentStackView.insertArrangedSubview(connectorView, at: 3)
        }
    }
    
    private func setupAddFavAnimationView() {
        animationView = .init(name: "added_fav")
        
        guard let animationView = animationView else { return }
        
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
    
    private func setupAddFavoritesButton() {
        addToFavouritesButton.setTitle(addFavoritesButtonConfiguration.title, for: .normal)
        addToFavouritesButton.backgroundColor = addFavoritesButtonConfiguration.color
        addToFavouritesButton.setTitleColor(addFavoritesButtonConfiguration.titleColor, for: .normal)
    }

}

// MARK: - Actions

extension EvStationDetailsViewController {
    
    // MARK: - Configuration
    
    private enum AnimationConfiguration {
        static let showDelay = 0.0
        static let hideDelay = 2.0
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
        animationView?.isHidden = false
        animationView?.play()
        perform(#selector(self.hideAddFavAnimation), with: self, afterDelay: AnimationConfiguration.hideDelay)
    }
    
    @objc private func hideAddFavAnimation(_ sender: Any) {
        animationView?.isHidden = true
    }
    
}
