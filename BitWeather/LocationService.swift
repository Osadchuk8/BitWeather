//
//  LocationHelper.swift
//  BitWeather
//
//  Created by Oleksandr on 2018-11-11.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation
import CoreLocation

class LocationService:NSObject {
    
    fileprivate let locMgr:CLLocationManager
    fileprivate let geoCoder:CLGeocoder
    public var currentLocation:CLLocation?
    public var currentCity:String=""
    public var isLocationServicesEnabled = false
    fileprivate var completionLocation: (String)->()
    
    
    override init() {
        
        locMgr = CLLocationManager()
        locMgr.desiredAccuracy = kCLLocationAccuracyKilometer

        geoCoder = CLGeocoder()
        currentLocation=nil
        
        completionLocation = {str in
        }
       
        
        super.init()
        locMgr.delegate=self

        
    }
    
    public func getCurrentLocation(completionOk: @escaping (String)->(), completionError: @escaping (String)->() ){
        if checkAuth() {
            locMgr.startUpdatingLocation()
            completionLocation=completionOk //passing fo locmgr delegatemethod use
        }else{
            //location not available
            completionError("Location service not available")
        }
        
    }
    
    //TODO: ambigous with next method
    public func getCityName(location: CLLocation, completion: @escaping (String)->() ){
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: {placemarks, error in
            
            if let e=error {
                print("--reverseGeocodeLocation() -> error: \(e.localizedDescription)")
                return
            }
            guard let addressDict = placemarks?[0].addressDictionary else {return}
            if let city = addressDict["City"] as? String {
                self.currentCity=city
//                print ("--currentCity=", self.currentCity)
            }
            completion(self.currentCity)
        })
    }
    
    fileprivate func getCurrentCityName(completion: @escaping (String)->()){
        guard let loc = currentLocation else{
            return
        }
        geoCoder.reverseGeocodeLocation(loc, completionHandler: {placemarks, error in
            if let e=error {
                print("--reverseGeocodeLocation() -> error: \(e.localizedDescription)")
                return
            }
            guard let addressDict = placemarks?[0].addressDictionary else {return}
            
            if let city = addressDict["City"] as? String {
                self.currentCity=city
//                print ("--currentCity=", self.currentCity)
            }
        
            completion(self.currentCity)
        })
    }
    
    private func checkAuth() -> Bool{
        if CLLocationManager.locationServicesEnabled(){
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
                isLocationServicesEnabled = true
                return true
            }else{
                locMgr.requestWhenInUseAuthorization()
                //check if autorisation was granted: didChangeAuthorization() delegate m.
                return false
            }
        }else{
            isLocationServicesEnabled=false
            return false
        }
    }
    
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("--didUpdateLocations() -> ok")
        if let loc = locMgr.location{
            currentLocation = loc
            getCurrentCityName(completion: completionLocation)
            locMgr.stopUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("**didUpdateLocations()->didFailWithError()")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.isLocationServicesEnabled = true
        }else{
            self.isLocationServicesEnabled = false
        }
    }
}

