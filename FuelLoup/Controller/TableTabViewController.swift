//
//  TableTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 16/11/2021.
//

import UIKit
import CoreLocation
import CoreData

final class TableTabViewController: UIViewController {
    
    enum DisplayMode {
        case regular
        case favourites
    }
    
    // MARK: - IB
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
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
    
//    private var modelCount: Int {
//        switch displayMode {
//        case .regular: return evStationsViewModel.count
//        case .favourites:
//            return 0
//        }
//    }
    
    var displayMode: DisplayMode = .regular
    var dataController: FuelLoupDataController?
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateEvStationLocations()
        
        switch displayMode {
        case .favourites:
            let fetchRequest: NSFetchRequest<FavouriteStation> = FavouriteStation.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            if let favoriteStations = try? dataController?.viewContext.fetch(fetchRequest) {
                favoriteStations.forEach { station in
                    let id = "\(station.id)"
                    let poi = Poi(name: station.poiName ?? "unknown", phone: station.poiPhone, url: nil)
                    let position = Position(lat: station.lat, lon: station.lng)
                    let chargingPark = station.parks
                    
                    let result = Result(id: id, poi: poi, address: nil, position: position, chargingPark: chargingPark, dataSources: nil)
                    
                    evStationsViewModel.append(ResultViewModel(result: result, currentLocation: nil))
                }
            }
        case .regular:
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            evStationsViewModel = appDelegate?.evStations ?? []
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedIndexPathRow = tableView.indexPathForSelectedRow?.row, let stationDetailsViewController = segue.destination as? EvStationDetailsViewController else { return }
        
        let selectedEvStation = evStationsViewModel[selectedIndexPathRow]
        
        stationDetailsViewController.chargingPark = selectedEvStation.result.chargingPark
        stationDetailsViewController.poi = selectedEvStation.result.poi
        
        if let dataSources = selectedEvStation.result.dataSources {
            stationDetailsViewController.poiDetailsId = dataSources.poiDetails?[0].id
            stationDetailsViewController.chargingAvailabilityId = dataSources.chargingAvailability.id
        }
        
        stationDetailsViewController.hidesBottomBarWhenPushed = true
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

// MARK: - UITableViewDataSource

extension TableTabViewController: UITableViewDataSource {
    
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

//extension TableTabViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        selectedEvStation = evStationsViewModel[indexPath.row]
//    }
//
//}

// MARK: - CLLocationManagerDelegate

extension TableTabViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = manager.location?.coordinate else { return }
        
        for var viewModel in evStationsViewModel {
            viewModel.currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        tableView.reloadData()
    }
    
    private func handleStationsLocationResponse(results: [Result]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        if let results = results, !results.isEmpty {
            tableView.reloadData()
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations loading error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
}
