//
//  ViewController.swift
//  Maps Direction
//
//  Created by Agus Cahyono on 2/9/17.
//  Copyright © 2017 balitax. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacesAPI
import SwiftyJSON
import Alamofire
import CoreLocation
import Foundation
import MapKit


enum Location {
	case startLocation
	case destinationLocation
}

class ViewController: UIViewController , GMSMapViewDelegate ,  CLLocationManagerDelegate {
	
	@IBOutlet weak var googleMaps: GMSMapView!
	@IBOutlet weak var startLocation: UITextField!
	@IBOutlet weak var destinationLocation: UITextField!
	

	var locationManager = CLLocationManager()
	var locationSelected = Location.startLocation
	
	var locationStart = CLLocation()
	var locationEnd = CLLocation()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
		locationManager.startUpdatingLocation()
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.startMonitoringSignificantLocationChanges()
		
		//Your map initiation code
		let camera = GMSCameraPosition.camera(withLatitude: 34.071200, longitude: -118.451690, zoom: 15.0)
		
		self.googleMaps.camera = camera
		self.googleMaps.delegate = self
		self.googleMaps?.isMyLocationEnabled = true
		self.googleMaps.settings.myLocationButton = true
		self.googleMaps.settings.compassButton = true
		self.googleMaps.settings.zoomGestures = true
		
	}
	
	// MARK: function for create a marker pin on map
	func createMarker(titleMarker: String, iconMarker: UIImage, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
		let marker = GMSMarker()
		marker.position = CLLocationCoordinate2DMake(latitude, longitude)
		marker.title = titleMarker
		marker.icon = iconMarker
		marker.map = googleMaps
	}
	
	//MARK: - Location Manager delegates
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Error to get location : \(error)")
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		
		let location = locations.last
		
		//let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
		
		//let locationTujuan = CLLocation(latitude: 34.071200, longitude: -118.451690)
		
		//createMarker(titleMarker: "Lokasi Tujuan", iconMarker: #imageLiteral(resourceName: "mapspin") , latitude: locationTujuan.coordinate.latitude, longitude: locationTujuan.coordinate.longitude)
		
		createMarker(titleMarker: "Lokasi Aku", iconMarker: #imageLiteral(resourceName: "mapspin") , latitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!)
		
//		drawPath(startLocation: location!, endLocation: locationTujuan)
		
		//self.googleMaps?.animate(to: camera)
		self.locationManager.stopUpdatingLocation()
		
	}
	
	// MARK: - GMSMapViewDelegate
	
	func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
		googleMaps.isMyLocationEnabled = true
	}
	
	func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
		googleMaps.isMyLocationEnabled = true
		
		if (gesture) {
			mapView.selectedMarker = nil
		}
	}
	
	func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
		googleMaps.isMyLocationEnabled = true
		return false
	}
	
	func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
		print("COORDINATE \(coordinate)") // when you tapped coordinate
	}
	
	func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
		googleMaps.isMyLocationEnabled = true
		googleMaps.selectedMarker = nil
		return false
	}
	
	

	//MARK: - this is function for create direction path, from start location to desination location
	
	func drawPath(startLocation: CLLocation, endLocation: CLLocation)
	{
		let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
		let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
		
		
		let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking&key=AIzaSyD4GxrTY2xyeCZrpyqCSLlIZoYfITkZs9o"
		
		Alamofire.request(url).responseJSON { response in
			//let jsonData = response.result.value as? NSDictionary
            //print(jsonData)
			print(response.request as Any)  // original URL request
			print(response.response as Any) // HTTP URL response3
            print("Response Data: ", try! JSON(data: response.data!))     // server data
			print(response.result as Any)   // result of response serialization
			
            
			//let json = try! JSON(data: response.data!)
            let json =  try! JSON(data: response.data!)
            //import json to firebase
            let routes = json["routes"].arrayValue
			// print route using Polyline
            for route in routes
            {
                print ("aaaaa")
                let routeOverviewPolyline = route["overview_polyline"].dictionary
                let points = routeOverviewPolyline?["points"]?.stringValue
                let path = GMSPath.init(fromEncodedPath: points!)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = UIColor.red
                polyline.map = self.googleMaps
                
                var yourArray = [String]()
                let legs = route["legs"].arrayValue;
                for leg in legs
                {
                    let steps = leg["steps"].arrayValue
                    for step in steps
                    {
                        let la = (step["end_location"]["lat"]).double
                        let ln = (step["end_location"]["lng"]).double
                        //yourArray.append(self.convertLatLongToAddress(latitude:la!, longitude:ln!))
                        self.getAddress(latitude: la!, longitude: ln!) { (address) in
                            print(address)
                            yourArray.append(address)
                        }
                    }
                }
                //function compute
            }
		}
	}
    
    func convertLatLongToAddress(latitude:Double,longitude:Double)->String{
       // var yourArray = [String]()
        var result : String = ""
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            // Location name
            if let locationName = placeMark.subThoroughfare {
                print (locationName)
                result = self.parseString(num: locationName)
            }
            // Street address
            if let street = placeMark.thoroughfare {
                print (street)
                result = result + " " + street;
            }
            print (result)
        })
        print (result)
        return result
    }
    
    func getAddress(latitude:Double,longitude:Double, handler: @escaping (String) -> Void)
    {
        var address: String = ""
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        //selectedLat and selectedLon are double values set by the app in a previous process
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            // Place details
            var placeMark: CLPlacemark?
            placeMark = placemarks?[0]
            
            // Address dictionary
            //print(placeMark.addressDictionary ?? "")
            var temp : String = ""
            
            // Location name
            if let locationName = placeMark?.subThoroughfare {
                temp += self.parseString(num: locationName)
            }
            
            // Street address
            if let street = placeMark?.thoroughfare{
                temp += " " + street
            }
            // Passing address back
            address = temp
            handler(address)
        })
    }
    
    func parseString (num: String)->String{
        
        let firstPart = num
        if let range = num.range(of: "–") {
            let firstPpart = num[num.startIndex..<range.lowerBound]
            
            let endIndex = firstPpart.index(firstPpart.endIndex, offsetBy: -2)
            let truncated = firstPpart.substring(to: endIndex)
            var newStr:String = truncated + String("0")
            newStr = newStr + String("0")
            return newStr
        }
        
        let endIndex = firstPart.index(firstPart.endIndex, offsetBy: -2)
        let truncated = firstPart.substring(to: endIndex)
        var newStr:String = truncated + String("0")
        newStr = newStr + String("0")
        return newStr
    }
    
    func calculateCrimeScore(/*1. csv reference 2. dict of route*/){
        // int score
        //for loop
        // if (key = number, value = street)
        // score += crime_score
        
    }
    
    
    
    
	// MARK: when start location tap, this will open the search location
	@IBAction func openStartLocation(_ sender: UIButton) {
		
		let autoCompleteController = GMSAutocompleteViewController()
		autoCompleteController.delegate = self
		
		// selected location
		locationSelected = .startLocation
		
		// Change text color
		UISearchBar.appearance().setTextColor(color: UIColor.black)
		self.locationManager.stopUpdatingLocation()
		
		self.present(autoCompleteController, animated: true, completion: nil)
	}
	
	// MARK: when destination location tap, this will open the search location
	@IBAction func openDestinationLocation(_ sender: UIButton) {
		
		let autoCompleteController = GMSAutocompleteViewController()
		autoCompleteController.delegate = self
		
		// selected location
		locationSelected = .destinationLocation
		
		// Change text color
		UISearchBar.appearance().setTextColor(color: UIColor.black)
		self.locationManager.stopUpdatingLocation()
		
		self.present(autoCompleteController, animated: true, completion: nil)
	}
	
	
	// MARK: SHOW DIRECTION WITH BUTTON
	@IBAction func showDirection(_ sender: UIButton) {
		// when button direction tapped, must call drawpath func
		self.drawPath(startLocation: locationStart, endLocation: locationEnd)
	}

}

// MARK: - GMS Auto Complete Delegate, for autocomplete search location
extension ViewController: GMSAutocompleteViewControllerDelegate {
	
	func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
		print("Error \(error)")
	}
	
	func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
		
		// Change map location
		let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 16.0
		)
		
		// set coordinate to text
		if locationSelected == .startLocation {
			startLocation.text = "\(place.coordinate.latitude), \(place.coordinate.longitude)"
			locationStart = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
			createMarker(titleMarker: "Location Start", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
		} else {
			destinationLocation.text = "\(place.coordinate.latitude), \(place.coordinate.longitude)"
			locationEnd = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
			createMarker(titleMarker: "Location End", iconMarker: #imageLiteral(resourceName: "mapspin"), latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
		}
		
		
		self.googleMaps.camera = camera
		self.dismiss(animated: true, completion: nil)
		
	}
	
	func wasCancelled(_ viewController: GMSAutocompleteViewController) {
		self.dismiss(animated: true, completion: nil)
	}
	
	func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}
	
	func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = false
	}
	
}

public extension UISearchBar {
	
	public func setTextColor(color: UIColor) {
		let svs = subviews.flatMap { $0.subviews }
		guard let tf = (svs.filter { $0 is UITextField }).first as? UITextField else { return }
		tf.textColor = color
	}
	
}
