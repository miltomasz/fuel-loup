//
//  MapTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import Foundation
import MapKit
import CoreLocation

final class MapTabViewController: UIViewController, DataControllerable {

    // MARK: - IB
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private var _dataController: FuelLoupDataController?
    
    var selectedEvStationId: String?
    var position: Position?
    var dataSources: DataSources?
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var chargingPark: ChargingPark?
    var dataController: FuelLoupDataController? {
        set {
            _dataController = newValue
        }
        get {
            return _dataController
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
             locationManager.delegate = self
             locationManager.desiredAccuracy = kCLLocationAccuracyBest
             locationManager.startUpdatingLocation()
         }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SegueIdentifires.showFavorites.rawValue:
            guard let favoritesViewController = segue.destination as? TableTabViewController else { return }
            
            favoritesViewController.displayMode = .favourites
            favoritesViewController.dataController = dataController
        case SegueIdentifires.showStationDetails.rawValue:
            guard let stationDetailsViewController = segue.destination as? EvStationDetailsViewController else { return }
            
            stationDetailsViewController.dataController = dataController
            stationDetailsViewController.chargingPark = chargingPark
            stationDetailsViewController.poi = poi
            stationDetailsViewController.poiDetailsId = poiDetailsId
            stationDetailsViewController.chargingAvailabilityId = chargingAvailabilityId
            stationDetailsViewController.hidesBottomBarWhenPushed = true
            
            guard let selectedEvStationId = selectedEvStationId else { return }
            
            stationDetailsViewController.selectedEvStation = ResultViewModel.create(from: selectedEvStationId, chargingPark: chargingPark, position: position, poi: poi, dataSources: dataSources)
        default: break
        }
    }
    
    private func handleStationsLocationResponse(results: [ResultModel]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        if let results = results, !results.isEmpty {
            setupTableTabViewModel(results: results)
            setupAnnotations(results: results)
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations load error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
    // MARK: - Setup
    
    private func setupAnnotations(results: [ResultModel]) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = createAnnotations(for: results)
        
        mapView.addAnnotations(annotations)
    }
    
    private func createAnnotations(for collection: [ResultModel]) -> [MKPointAnnotation] {
        var annotations = [MKPointAnnotation]()
        
        for result in collection {
            let lat = CLLocationDegrees(result.position.lat)
            let long = CLLocationDegrees(result.position.lon)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = EvStationPointAnnotation()
            annotation.coordinate = coordinate
            annotation.poi = result.poi
            annotation.selectedEvStationId = result.id
            annotation.dataSources = result.dataSources
            annotation.position = result.position
            
            if let chargingPark = result.chargingPark {
                annotation.title = chargingPark.connectors.compactMap { $0.connectorType }.joined(separator: ", ")
                annotation.chargingPark = result.chargingPark
            }
            
            if let dataSources = result.dataSources {
                annotation.poiDetailsId = dataSources.poiDetails?[0].id
                annotation.chargingAvailabilityId = dataSources.chargingAvailability.id
            }
            
            if let streetName = result.address?.streetName, let streetNumber = result.address?.streetNumber {
                annotation.subtitle = "\(streetName) \(streetNumber)"
            } else {
                annotation.subtitle = "No data loaded"
            }
            
            annotations.append(annotation)
        }
        
        return annotations
    }
    
    private func setupTableTabViewModel(results: [ResultModel]) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        guard let currentLocation = locationManager.location else { return }
        
        appDelegate?.evStations = results.map { result in
            ResultViewModel(result: result, currentLocation: currentLocation)
        }.sorted(by: { rvm1, rvm2 in
            do {
                return try LocationHelper.distanceSorting(currentLocation, rvm1.result, rvm2.result)
            } catch {
                debugPrint("Could not sort results: \(error)")
                return false
            }
        })
    }
    
}

// MARK: - MKMapViewDelegate

extension MapTabViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        
        let annotationIdentifier = "identifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            
            let moreIcon = UIImage(named: "more-info-icon")
            let rightButton = UIButton(type: .infoLight)
            rightButton.setImage(moreIcon, for: .normal)
            rightButton.imageView?.contentMode = .scaleAspectFill
            rightButton.tag = annotation.hash
            rightButton.addTarget(self, action: #selector(onTap(sender:)), for: .touchUpInside)
            
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = rightButton
        }
        
        annotationView?.annotation = annotation
        annotationView?.image = UIImage(named: "charging-station-icon")
        
        return annotationView
    }
    
    @objc func onTap(sender: AnyObject) {
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            guard let annotation = view.annotation as? EvStationPointAnnotation else { return }
            
            selectedEvStationId = annotation.selectedEvStationId
            dataSources = annotation.dataSources
            position = annotation.position
            poi = annotation.poi
            poiDetailsId = annotation.poiDetailsId
            chargingAvailabilityId = annotation.chargingAvailabilityId
            chargingPark = annotation.chargingPark
            
            let selectedAnnotations = mapView.selectedAnnotations
            for annotation in selectedAnnotations {
                mapView.deselectAnnotation(annotation, animated: false)
            }
            
            performSegue(withIdentifier: "showStationDetails", sender: nil)
        }
    }
    
}

// MARK: - CLLocationManagerDelegate

extension MapTabViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = manager.location?.coordinate else { return }

        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        
        NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
        
        FuelLoupClient.getNearestEvStations(latitude: coordinate.latitude, longitude: coordinate.longitude, completion: handleStationsLocationResponse(results:error:))
    }
    
}
