//
//  MapViewController.swift
//  ios-googlemaps-view
//
//  Created by User on 2018-11-06.
//  Copyright © 2018 User. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreData

class MapViewController: UIViewController {


    @IBOutlet weak var zoomOutButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var zoomInButton: UIButton!
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    var zoom : Float = 15.0
    var marker = GMSMarker()
    var locations: [NSManagedObject] = []
    var placesEv = NSArray()
    
    @IBOutlet weak var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationButton.isEnabled = false
        mapView.delegate = self
        
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
        
        loadCoreData()
        
    }
    
    func getViewContext() -> NSManagedObjectContext? {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return nil
        }
        return appDelegate.persistentContainer.viewContext
    }
    
    func loadCoreData(){
        
        if let managedContext = getViewContext(){
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
            
            do {
                locations = try managedContext.fetch(fetchRequest)
                placesEv = arrayFromJsonFromFile(name: "opencharge")
                if (locations.count != placesEv.count){
                    print("Reloading with new locations")
                    for location in locations {
                        managedContext.delete(location)
                    }
                    locations.removeAll()
                }
                createCoreDataOpenCharge(placesEv: placesEv)
                locations = try managedContext.fetch(fetchRequest)
            
                loadPlaces(locations)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    func createCoreDataOpenCharge(placesEv : NSArray){
        var dropped=0
        if let managedContext = getViewContext(){
            var position = 0
            for place in placesEv{
                let p = place as! NSDictionary
                let entity = NSEntityDescription.entity(forEntityName: "Location", in: managedContext)!
                position += 1
                
                if (p.isEmpty(key: "OperatorInfo")){
                    dropped += 1
                    continue
                }
                let operatorInfo = p.value(forKey: "OperatorInfo") as! NSDictionary
                if (p.isEmpty(key: "AddressInfo")){
                    dropped += 1
                    continue
                }
                let addressInfo = p.value(forKey: "AddressInfo") as! NSDictionary
                
                //Extracting fields
                let name = operatorInfo.safeString(forKey: "Title", defaultValue: "EV Charge")
                let locName = operatorInfo.safeString(forKey: "WebsiteURL", defaultValue: "No URL")
                let latitude = addressInfo.value(forKey: "Latitude") as! Double
                let longitude = addressInfo.value(forKey: "Longitude") as! Double
                
                let newLocation = NSManagedObject(entity: entity, insertInto: managedContext)
                newLocation.setValue(name , forKeyPath:"name")
                newLocation.setValue(latitude, forKeyPath:"latitude")
                newLocation.setValue(longitude, forKeyPath:"longitude")
                newLocation.setValue("Electric Vehicle Charge", forKeyPath:"type")
                newLocation.setValue(locName, forKeyPath:"desc")
                newLocation.setValue(position-1, forKeyPath:"position")
                
                
                do {
                    try managedContext.save()
                    locations.append(newLocation)
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
            
        }
        print("Dropped \(dropped) locations")
        
    }
    
    
    func loadPlaces(_ places: [NSManagedObject] ){
        print("Loading places (\(places.count))")
        let image = UIImage(named: "ev-charge-20.png")
        for place in places {
            let latitude = place.value(forKeyPath:"latitude") as! Double
            let longitude = place.value(forKeyPath:"longitude") as! Double
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            marker.title = place.value(forKeyPath:"name") as? String
            marker.snippet = (place.value(forKeyPath:"type") as? String)! + "\n" + (place.value(forKeyPath:"desc") as? String)!
            //marker.icon = GMSMarker.markerImage(with: UIColor.blue)
            marker.icon = image
            marker.zIndex = place.value(forKey: "position") as! Int32
            marker.map = mapView
        }
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
    
    @IBAction func zoomClick(_ sender: UIButton) {
        if (sender.isEqual(zoomInButton)){
            self.zoom += 1
            self.mapView.animate(toZoom: self.zoom)
        }
        if (sender.isEqual(zoomOutButton)){
            self.zoom -= 1
            self.mapView.animate(toZoom: self.zoom)
        }
        if (sender.isEqual(locationButton)){
            if let location = self.currentLocation {
                self.updateLocation(location)
            }
            
        }
    }


}


extension MapViewController : CLLocationManagerDelegate {
    
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("New location: \(location)")
        currentLocation = location
        locationButton.isEnabled = true
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


extension MapViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        print("Position \(marker.zIndex)")
        print(placesEv.object(at: Int(marker.zIndex)))
        return false
    }
    
}
