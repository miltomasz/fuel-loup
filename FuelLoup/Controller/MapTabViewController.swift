//
//  MapTabViewController.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 08/07/2021.
//

import Foundation
import MapKit
import CoreLocation

class MapTabViewController: UIViewController {
    
    // MARK: - IB
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    let locationManager = CLLocationManager()
    var poi: Poi?
    var poiDetailsId: String?
    var chargingAvailabilityId: String?
    var chargingPark: ChargingPark?
    
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
        guard let stationDetailsViewController = segue.destination as? EvStationDetailsViewController else { return }
        
        stationDetailsViewController.chargingPark = chargingPark
        stationDetailsViewController.poi = poi
        stationDetailsViewController.poiDetailsId = poiDetailsId
        stationDetailsViewController.chargingAvailabilityId = chargingAvailabilityId
        stationDetailsViewController.hidesBottomBarWhenPushed = true
    }
    
    private func handleStationsLocationResponse(results: [Result]?, error: Error?) {
        NetworkHelper.showLoader(false, activityIndicator: activityIndicator)
        
        if let results = results, !results.isEmpty {
            setupAnnotations(results: results)
        } else {
            guard let tabBarController = tabBarController else { return }
            
            NetworkHelper.showFailurePopup(title: "EV charging stations load error", message: error?.localizedDescription ?? "", on: tabBarController)
        }
    }
    
    // MARK: - Setup
    
    private func setupAnnotations(results: [Result]) {
        mapView.removeAnnotations(mapView.annotations)
        
        let annotations = createAnnotations(for: results)
        
        mapView.addAnnotations(annotations)
    }
    
    private func createAnnotations(for collection: [Result]) -> [MKPointAnnotation] {
        var annotations = [MKPointAnnotation]()
        
        for result in collection {
            let lat = CLLocationDegrees(result.position.lat)
            let long = CLLocationDegrees(result.position.lon)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = EvStationPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = result.chargingPark.connectors.map { $0.connectorType }.joined(separator: ", ")
            
            annotation.chargingPark = result.chargingPark
            annotation.poi = result.poi
            annotation.poiDetailsId = result.dataSources.poiDetails?[0].id
            annotation.chargingAvailabilityId = result.dataSources.chargingAvailability.id
            
            if let streetName = result.address.streetName, let streetNumber = result.address.streetNumber {
                annotation.subtitle = "\(streetName) \(streetNumber)"
            } else {
                annotation.subtitle = "No data loaded"
            }
            
            annotations.append(annotation)
        }
        
        return annotations
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
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        guard let annotation = view.annotation as? EvStationPointAnnotation else { return }
//
//        poiDetailsId = annotation.poiDetailsId
//        chargingAvailabilityId = annotation.chargingAvailabilityId
//
//        let selectedAnnotations = mapView.selectedAnnotations
//        for annotation in selectedAnnotations {
//            mapView.deselectAnnotation(annotation, animated: false)
//        }
//
//        performSegue(withIdentifier: "showStationDetails", sender: nil)
//    }
    
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
