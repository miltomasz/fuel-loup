//
//  TableTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 16/11/2021.
//

import UIKit
import CoreLocation

final class TableTabViewController: UIViewController {
    
    // MARK: - IB
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private var evStationsViewModel: [ResultViewModel] {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.evStations ?? []
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        cell.address.text = "\(evStationLocation.result.address.streetName ?? "") \(evStationLocation.result.address.streetNumber ?? "")"
        cell.distance.text = evStationLocation.distance
        
        if let poiDetailsId = evStationLocation.result.dataSources.poiDetails?[0].id {
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

// MARK: - CLLocationManagerDelegate

extension TableTabViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = manager.location?.coordinate else { return }
        
        NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
        
        FuelLoupClient.getNearestEvStations(latitude: coordinate.latitude, longitude: coordinate.longitude, completion: handleStationsLocationResponse(results:error:))
    }
    
    private func handleStationsLocationResponse(results: [Result]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        if let results = results, !results.isEmpty {
//            evStationLocations = results
            tableView.reloadData()
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations loading error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
}
