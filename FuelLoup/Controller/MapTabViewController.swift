//
//  MapTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import Foundation
import MapKit
import CoreLocation

final class MapTabViewController: UIViewController, DataControllerAware {

    // MARK: - IB
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    private lazy var overlay: MKTileOverlay = {
        let overlayURL = "https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png"
        let overlay = MKTileOverlay(urlTemplate: overlayURL)
        overlay.canReplaceMapContent = true
        return overlay
    }()
    private let locationManager = CLLocationManager()
    private var _dataController: FuelLoupDataController?
    private let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    var selectedEvStationId: String?
    var position: Position?
    var dataSources: DataSources?
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var address: Address?
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
        setupLocationManager()
        refreshMapView()
        mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.requestWhenInUseAuthorization()
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
            favoritesViewController.hidesBottomBarWhenPushed = true
        case SegueIdentifires.showStationDetails.rawValue:
            guard let stationDetailsViewController = segue.destination as? EvStationDetailsViewController else { return }
            
            stationDetailsViewController.dataController = dataController
            stationDetailsViewController.chargingPark = chargingPark
            stationDetailsViewController.poi = poi
            stationDetailsViewController.poiDetailsId = poiDetailsId
            stationDetailsViewController.chargingAvailabilityId = chargingAvailabilityId
            stationDetailsViewController.hidesBottomBarWhenPushed = true
            
            guard let selectedEvStationId = selectedEvStationId else { return }
            
            stationDetailsViewController.selectedEvStation = ResultViewModel.create(from: selectedEvStationId, address: address, chargingPark: chargingPark, position: position, poi: poi, dataSources: dataSources)
        case SegueIdentifires.showMapSettings.rawValue:
            guard let mapSettingsViewController = segue.destination as? MapSettingsViewController else { return }
            
            mapSettingsViewController.delegate = self
        default: break
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
            annotation.address = result.address
            
            if let chargingPark = result.chargingPark {
                annotation.title = result.poi.name
                annotation.chargingPark = result.chargingPark
            }
            
            if let dataSources = result.dataSources {
                annotation.poiDetailsId = dataSources.poiDetails?[0].id
                annotation.chargingAvailabilityId = dataSources.chargingAvailability.id
            }
            
            if let streetName = result.address?.streetName, let streetNumber = result.address?.streetNumber {
                annotation.subtitle = "\(streetName) \(streetNumber)"
            } else {
                annotation.subtitle = "annotation.no.data".localized
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
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = 30.0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .restricted, .denied:
                handleDeniedLocationServices()
            case .authorizedAlways, .authorizedWhenInUse:
                updateLocation()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        } else {
            handleDeniedLocationServices()
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapTabViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let annotationIdentifier = "fuelLoupAnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        
        annotationView?.annotation = annotation
        annotationView?.image = UIImage(named: "charging-station-icon")
        annotationView?.frame.size = CGSize(width: 48, height: 48)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let mapCoordinate = mapView.centerCoordinate

        let mapRegion = MKCoordinateRegion(center: mapCoordinate, span: span)
        let lat = mapRegion.center.latitude
        let lng = mapRegion.center.longitude
//        mapView.setRegion(region, animated: true)
//        mapView.mapType = .mutedStandard
//        mapView.showsUserLocation = true
//
//        NetworkHelper.showLoader(true, activityIndicator: activityIndicator)
//
//        FuelLoupClient.getNearestEvStations(latitude: coordinate.latitude, longitude: coordinate.longitude, completion: handleStationsLocationResponse(results:error:))
    }
    
    // MARK: Map overlay
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }
}

extension MapTabViewController: MapOverlayViewDelegate {
    func refreshMapView() {
        let blackWhiteMapOn = UserDefaults.standard.bool(forKey: "BlackWhiteMap")
        if blackWhiteMapOn {
            mapView.addOverlay(overlay)
        } else {
            mapView.removeOverlay(overlay)
        }
    }
}

// MARK: - ExampleCalloutViewDelegate

extension MapTabViewController: ExampleCalloutViewDelegate {
    func mapView(_ mapView: MKMapView, didTapDetailsButton button: UIButton, for annotation: MKAnnotation) {
        guard let annotation = annotation as? EvStationPointAnnotation else { return }

        selectedEvStationId = annotation.selectedEvStationId
        dataSources = annotation.dataSources
        position = annotation.position
        poi = annotation.poi
        poiDetailsId = annotation.poiDetailsId
        chargingAvailabilityId = annotation.chargingAvailabilityId
        chargingPark = annotation.chargingPark
        address = annotation.address
        
        let selectedAnnotations = mapView.selectedAnnotations
        for annotation in selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: false)
        }

        performSegue(withIdentifier: SegueIdentifires.showStationDetails.rawValue, sender: nil)
    }
}

// MARK: - CLLocationManagerDelegate

extension MapTabViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .restricted, .denied:
            handleDeniedLocationServices()
        case .authorizedAlways, .authorizedWhenInUse:
            updateLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = manager.location?.coordinate else { return }
        
        manager.stopUpdatingLocation()
        manager.delegate = nil

        let region = MKCoordinateRegion(center: coordinate, span: span)

        mapView.setRegion(region, animated: true)
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true

        NetworkHelper.showLoader(true, activityIndicator: activityIndicator)

        FuelLoupClient.getNearestEvStations(latitude: coordinate.latitude, longitude: coordinate.longitude, completion: handleStationsLocationResponse(results:error:))
    }
    
    private func handleStationsLocationResponse(results: [ResultModel]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        locationManager.stopUpdatingLocation()
        
        if let results = results, !results.isEmpty {
            setupTableTabViewModel(results: results)
            setupAnnotations(results: results)
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations load error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
    private func handleDeniedLocationServices() {
        NetworkHelper.hideLoaderIfStopped(activityIndicator: activityIndicator)
        guard let tabBarController = tabBarController else { return }
        
        NetworkHelper.showFailurePopup(title: "Warning", message: "To use the application you need to enable Location Services in Settings -> Privacy -> Location Services", on: tabBarController)
    }
    
    private func updateLocation() {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
}
