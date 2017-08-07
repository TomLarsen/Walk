//
//  ViewController.swift
//  Walk
//
//  Created by Tom Larsen on 28/07/2017.
//  Copyright © 2017 Tom Larsen. All rights reserved.
//
// https://developers.google.com/maps/documentation/ios-sdk/current-place-tutorial
// http://www.vladmarton.com/draw-text-on-image-programmatically-and-use-it-as-google-maps-marker-swift-3/
// https://gist.github.com/GuillaumeJasmin/70ea310bc4b91e509473
// https://stackoverflow.com/questions/15820199/how-to-label-map-markers-in-google-maps-ios
// https://www.raywenderlich.com/109888/google-maps-ios-sdk-tutorial

import UIKit;
import GoogleMaps;
import GooglePlaces;

class ViewController: UIViewController, GMSMapViewDelegate
{
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 12.0
    var GMSMARKER_ICON = false;
    
    let defaultLocation = CLLocation(latitude: 50.97, longitude: 5.55)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("ViewDidLoad");
        // Do any additional setup after loading the view, typically from a nib.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestAlwaysAuthorization();
        locationManager.distanceFilter = 50;
        locationManager.startUpdatingLocation();
        locationManager.delegate = self;
        
        placesClient = GMSPlacesClient.shared();
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                                 longitude: defaultLocation.coordinate.longitude,
                                                 zoom: zoomLevel);
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera);
        mapView.settings.myLocationButton = true;
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        
        mapView.isMyLocationEnabled = true;
        mapView.settings.zoomGestures = true;
        mapView.settings.compassButton = true;
        mapView.settings.myLocationButton = true;
        mapView.delegate = self;
        
        view.addSubview(mapView);
        mapView.isHidden = true;
        
        let knooppunten = readDataFromFile(fileName: "knooppunten.2017.07.30", fileType: "txt");

        //maxValue Title: 573
        //exception 30a (Limburg)
        var occurences = [String: Int]();
        for knooppunt in (knooppunten as? [Knooppunt])!
        {
            if (occurences[knooppunt.title] != nil)
            {
                occurences[knooppunt.title] = occurences[knooppunt.title]! + 1;
            }
            else
            {
                occurences[knooppunt.title] = 1;
            }
            if (knooppunt.title == "77")
            {
                let title = knooppunt.title;
                let latitude = knooppunt.lat;
                let longitude = knooppunt.lon;
                //print ("\(title) \(latitude) \(longitude)");
                createMarker(title: title!, lat: latitude!, lon: longitude!);
            }
        }
        
        for (k,v) in Array(occurences).sorted(by: {$0.0 < $1.0}) {
            print("\(k):\(v)")
        }
    }
    
    func readDataFromFile(fileName:String, fileType: String) -> NSMutableArray!
    {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
        else { return nil; }
        do
        {
            let content = try String(contentsOfFile: filepath, encoding: .utf8);
            let data = cleanRows(file: content);
            return csv(data: data);
        } catch
        {
            print("File Read Error for file \(filepath)");
            return nil;
        }
    }
    
    func cleanRows(file:String)->String
    {
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\"", with: "")
        return cleanFile;
    }
    
    func csv(data: String) -> NSMutableArray
    {
        let knooppunten : NSMutableArray = [];
        let rows = data.components(separatedBy: "\n")
        for row in rows
        {
            if row.contains(",")
            {
                let columns = row.components(separatedBy: ",");
                let knooppunt:Knooppunt = Knooppunt()
                knooppunt.title = String(columns[2]);
                knooppunt.lat = Double(columns[1]);
                knooppunt.lon = Double(columns[0]);
                knooppunt.area = columns[3];
            
            knooppunten.add(knooppunt);
            }
        }
        return knooppunten;
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createMarker(title: String, lat: Double, lon: Double)
    {
        // Create a marker
        print("creating marker");
        let marker = GMSMarker();
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: lon);
        
        if (GMSMARKER_ICON == true)
        {
            let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 40)))
            text.text = String(title)
            text.font = UIFont.boldSystemFont(ofSize:11.0);
            text.textAlignment = NSTextAlignment.center
        
        
            let dynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 40)))
            dynamicView.backgroundColor=UIColor.clear;
        
            var imageViewForPinMarker : UIImageView
            imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 40)))
            imageViewForPinMarker.image = UIImage(named:"ic_marker_orange.png")
        
            imageViewForPinMarker.addSubview(text)
            dynamicView.addSubview(imageViewForPinMarker)
        
            UIGraphicsBeginImageContextWithOptions(dynamicView.frame.size, false, UIScreen.main.scale)
            dynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        
            marker.icon = imageConverted
        }
        
        marker.title = String(title);
        marker.snippet = "";
        marker.map = mapView
    }
    
    func snapToMarkerIfItIsOutsideViewport(m: GMSMarker)
    {
        var region = GMSVisibleRegion();
        var bounds = GMSCoordinateBounds();
        region = mapView.projection.visibleRegion();
        bounds = GMSCoordinateBounds(region:region);
        if (!bounds.contains(m.position))
        {
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
    {
        print ("You tapped Marker: \(marker.title!)");
        return true;
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
    }
}


extension ViewController: CLLocationManagerDelegate
{
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        if (mapView.isHidden)
        {
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: zoomLevel)
            mapView.isHidden = false
            mapView.camera = camera
        }
        else
        {
            print("Camera move");
            let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                  longitude: location.coordinate.longitude,
                                                  zoom: mapView.camera.zoom)
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status
        {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}

