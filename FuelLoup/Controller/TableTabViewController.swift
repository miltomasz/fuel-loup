//
//  TableTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 16/11/2021.
//

import UIKit
import CoreLocation
import CoreData

final class TableTabViewController: UIViewController, DataControllerAware {
    
    // MARK: - Configuration
    
    enum DisplayMode {
        case regular
        case favourites
    }
    
    // MARK: - IB
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var favoritesIconButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private var _evStationsViewModel: [ResultViewModel]?
    private var evStationsViewModel: [ResultViewModel] {
        set {
            _evStationsViewModel = newValue
        }
        get {
            if let evStationsViewModel = _evStationsViewModel {
                return evStationsViewModel
            }
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            return appDelegate?.evStations ?? []
        }
    }
    
    private var _dataController: FuelLoupDataController?
    var dataController: FuelLoupDataController? {
        set {
            _dataController = newValue
        }
        get {
            return _dataController
        }
    }
    var displayMode: DisplayMode = .regular

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        setupTableView()
        updateEvStationLocations()
        
        switch displayMode {
        case .favourites:
            let fetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            guard let favoriteStations = try? dataController?.viewContext.fetch(fetchRequest) else { return }
            
            evStationsViewModel = favoriteStations.map { station -> ResultViewModel in
                let id = station.id ?? ""
                let poi = Poi(name: station.poiName ?? "unknown", phone: station.poiPhone, url: nil)
                let position = Position(lat: station.lat, lon: station.lng)
                let chargingPark = station.parks
                let address = station.address
                
                let result = ResultModel(id: id, poi: poi, address: address, position: position, chargingPark: chargingPark, dataSources: nil)
                return ResultViewModel(result: result, currentLocation: nil)
            }
        case .regular:
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            evStationsViewModel = appDelegate?.evStations ?? []
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SegueIdentifires.showFavorites.rawValue:
            guard let favoritesViewController = segue.destination as? TableTabViewController else { return }
            
            favoritesViewController.displayMode = .favourites
            favoritesViewController.dataController = dataController
        case SegueIdentifires.showStationDetails.rawValue:
            guard let selectedIndexPathRow = tableView.indexPathForSelectedRow?.row, let stationDetailsViewController = segue.destination as? EvStationDetailsViewController else { return }
            
            let selectedEvStation = evStationsViewModel[selectedIndexPathRow]
            
            stationDetailsViewController.chargingPark = selectedEvStation.result.chargingPark
            stationDetailsViewController.poi = selectedEvStation.result.poi
            stationDetailsViewController.selectedEvStation = selectedEvStation
            stationDetailsViewController.dataController = dataController
            stationDetailsViewController.tableViewRefreshDelegate = self
            
            if let dataSources = selectedEvStation.result.dataSources {
                stationDetailsViewController.poiDetailsId = dataSources.poiDetails?[0].id
                stationDetailsViewController.chargingAvailabilityId = dataSources.chargingAvailability.id
            }
            
            stationDetailsViewController.hidesBottomBarWhenPushed = true
        default: break
        }
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        switch displayMode {
        case .favourites:
            favoritesIconButton.isEnabled = false
            favoritesIconButton.tintColor = UIColor.clear
        case .regular:
            favoritesIconButton.isEnabled = true
            favoritesIconButton.tintColor = UIColor.systemPurple
        }
    }
    
    private func setupTableView() {
        tableView.removeExtraCellLines()
    }
    
    private func updateEvStationLocations() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
             locationManager.delegate = self
             locationManager.desiredAccuracy = kCLLocationAccuracyBest
             locationManager.startUpdatingLocation()
         }
    }

}

// MARK: - TableViewRefreshDelegate

extension TableTabViewController: TableViewRefreshDelegate {
    
    func refreshTable() {
        switch displayMode {
        case .favourites:
            let fetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            guard let favoriteStations = try? dataController?.viewContext.fetch(fetchRequest) else { return }
            
            evStationsViewModel = favoriteStations.map { station -> ResultViewModel in
                let id = station.id ?? ""
                let poi = Poi(name: station.poiName ?? "unknown", phone: station.poiPhone, url: nil)
                let position = Position(lat: station.lat, lon: station.lng)
                let chargingPark = station.parks
                let address = station.address
                
                let result = ResultModel(id: id, poi: poi, address: address, position: position, chargingPark: chargingPark, dataSources: nil)
                return ResultViewModel(result: result, currentLocation: nil)
            }
            tableView.reloadData()
        case .regular: break
        }
    }
    
}

// MARK: - UITableViewDataSource

extension TableTabViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // its not used when trailingSwipeActionsConfigurationForRowAt in UITableViewDelegate is used
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            let favoriteStationToDelete = evStationsViewModel[indexPath.row]
//            evStationsViewModel.remove(at: indexPath.row)
//
//            let idPredicate = NSPredicate(format: "id == %@", favoriteStationToDelete.id)
//
//            let favFetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
//            favFetchRequest.predicate = idPredicate
//
//            do {
//                guard let dataController = dataController else { return }
//
//                let toDeleteFavs = try dataController.viewContext.fetch(favFetchRequest)
//                guard let favToDelete = toDeleteFavs.first else { return }
//
//                dataController.viewContext.delete(favToDelete)
//                try dataController.viewContext.save()
//
//                tableView.deleteRows(at: [indexPath], with: .automatic)
//            } catch {
//                debugPrint("Could not delete favorite station from core data: \(error)")
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return evStationsViewModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "EvStationLocationCell", for: indexPath) as? EvStationLocationCell else { return EvStationLocationCell() }
        
        let evStationLocation = evStationsViewModel[indexPath.row]
        let evStationName = EvStationHelper.extractStationName(from: evStationLocation.result.poi)
        
        cell.name.text = evStationName
        cell.address.text = "\(evStationLocation.result.address?.streetName ?? "") \(evStationLocation.result.address?.streetNumber ?? "")"
        cell.distance.text = evStationLocation.distance
        
        if let poiDetailsId = evStationLocation.result.dataSources?.poiDetails?[0].id {
            FuelLoupClient.getEvStationDetails(id: poiDetailsId) { poiDetails, error in
                guard let poiDetails = poiDetails, let photos = poiDetails.result.photos, photos.count > 0 else { return }
                
                FuelLoupClient.getPhoto(id: photos[0].id) { image, error in
                    guard let image = image else {
                        cell.evStationimageView.image = UIImage(named: "default-station-icon")
                        cell.evStationimageView.contentMode = .scaleAspectFill
                        return
                    }
                    
                    cell.evStationimageView.image = image
                }
            }
        } else {
            cell.evStationimageView.image = UIImage(named: "default-station-icon")
            cell.evStationimageView.contentMode = .scaleAspectFill
        }
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension TableTabViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, sourceView, completionHandler) in
            guard let self = self else { return }
            
            let favoriteStationToDelete = self.evStationsViewModel[indexPath.row]
            
            self.dataController?.delete(favoriteStationToDelete) { result in
                switch result {
                case .success:
                    self.evStationsViewModel.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                case .failure:
                    NetworkHelper.showFailurePopup(title: "Error", message: "Could not delete favorite station", on: self)
                }
            }
            completionHandler(true)
        }
        
        delete.backgroundColor = UIColor.systemPurple
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }

}

// MARK: - CLLocationManagerDelegate

extension TableTabViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = manager.location?.coordinate else { return }
        
        for var viewModel in evStationsViewModel {
            viewModel.currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        tableView.reloadData()
    }
    
    private func handleStationsLocationResponse(results: [ResultModel]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        if let results = results, !results.isEmpty {
            tableView.reloadData()
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations loading error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
}
