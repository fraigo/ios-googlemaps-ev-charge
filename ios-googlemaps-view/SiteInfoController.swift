//
//  SiteInfoController.swift
//  ios-googlemaps-view
//
//  Created by User on 2018-11-19.
//  Copyright © 2018 User. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import MapKit

class SiteInfoController: UIViewController {
    
    var info: NSDictionary!
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    

    @IBOutlet weak var webLabel: UILabel!
    @IBOutlet weak var siteTitle: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBAction func onOpenMapClick(_ sender: Any) {
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        
        let regionSpan =   MKCoordinateRegion(center: coordinates, latitudinalMeters: 100, longitudinalMeters: 100)
        
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        
        let mapItem = MKMapItem(placemark: placemark)
        
        mapItem.name = siteTitle.text
        
        mapItem.openInMaps(launchOptions:[
        MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center)
        ] as [String : Any])
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(info)
        
        
        // Create a location
        let location2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // Create a camera view
        let camera = GMSCameraPosition.camera(withTarget: location2D, zoom: 18)
        mapView.mapType =  .satellite
        // Locate in map
        mapView.animate(to: camera)
        
        // Do any additional setup after loading the view.
        siteTitle.text = info.safeString(forKey: "OperatorInfo.Title", defaultValue: "No name")
        
        addressLabel.text = info.safeString(forKey: "AddressInfo.AddressLine1", defaultValue: "No address")
        
        webLabel.text = info.safeString(forKey: "OperatorInfo.WebsiteURL", defaultValue: "No web site")
        
        phoneLabel.text = info.safeString(forKey: "AddressInfo.ContactTelephone1", defaultValue: "No phone number")
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        marker.title = siteTitle.text
        marker.snippet = addressLabel.text
        marker.icon = GMSMarker.markerImage(with: UIColor.green)
        marker.map = mapView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClick(_ sender: Any) {
        self.dismiss(animated: true) {
            print("Closed")
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
