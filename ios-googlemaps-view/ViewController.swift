//
//  ViewController.swift
//  ios-googlemaps-view
//
//  Created by User on 2018-11-06.
//  Copyright © 2018 User. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {

    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoom : Float = 15.0
    var marker = GMSMarker()
    
    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a location
        let location2D = CLLocationCoordinate2D(latitude: 49.281, longitude: -123.121)
        // Create a camera view
        let camera = GMSCameraPosition.camera(withTarget: location2D, zoom: zoom)
        // Locate in map
        mapView.animate(to: camera)
        
        // To create a mapview right in the main view
        //view = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        
        // detect location
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        // places client
        placesClient = GMSPlacesClient.shared()
        
    }

    
    func updateLocation(_ location: CLLocation){
        // camera in location
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoom)
        mapView.animate(to: camera)
        // set parker position
        marker.position = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude )
        marker.title = "Current location"
        marker.snippet = "\(location.coordinate.latitude) : \(location.coordinate.longitude)"
        marker.map = mapView
        
        // detect places
        placesClient.currentPlace { (list, error) in
            if (error == nil){
                if let likelihoods = list?.likelihoods {
                    if (likelihoods.count>0){
                        print("Place: \(likelihoods[0].place.name) \(likelihoods[0].likelihood)")
                        self.marker.title = likelihoods[0].place.name
                        self.marker.snippet = likelihoods[0].place.formattedAddress
                    }
                }
            }else{
                print("Places Error: \(error.debugDescription)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.mapView.animate(toZoom: self.zoom + 1.0)
        }
    }


}


extension ViewController : CLLocationManagerDelegate {
    
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("New location: \(location)")
        currentLocation = location
        updateLocation(location)
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
