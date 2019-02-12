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
    fileprivate var delayedCompletion: (String)->()
    
    
    override init() {
        
        locMgr = CLLocationManager()
        locMgr.desiredAccuracy = kCLLocationAccuracyKilometer

        geoCoder = CLGeocoder()
        currentLocation=nil
        
        delayedCompletion = {str in
        }
        
        super.init()
        checkAuth()
        locMgr.delegate=self

        
    }
    
    public func getCurrentLocation(completion: @escaping (String)->() ){
//        print("--getCurrentLocation()")
        locMgr.startUpdatingLocation()
        delayedCompletion=completion
    }
    
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
    
    private func checkAuth(){
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
            return
        }else{
            locMgr.requestWhenInUseAuthorization()
        }
        
    }
    
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("--didUpdateLocations() -> ok")
        if let loc = locMgr.location{
            currentLocation = loc
            getCurrentCityName(completion: delayedCompletion)
            locMgr.stopUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("**didUpdateLocations()->didFailWithError()")
    }
}

