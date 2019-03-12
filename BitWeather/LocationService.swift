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
//    public var isLocationServicesEnabled = false
    fileprivate var completionLocation: (String)->()
    fileprivate var completionAuthGranted: ()->()
    fileprivate var completionAuthDenied: ()->()
    fileprivate var locationStatusInitial:CLAuthorizationStatus
    
    override init() {
        
        locMgr = CLLocationManager()
        locMgr.desiredAccuracy = kCLLocationAccuracyKilometer
        geoCoder = CLGeocoder()
        currentLocation=nil
    
        completionLocation = {str in
        }
        completionAuthGranted = {}
        completionAuthDenied = {}
       locationStatusInitial = CLLocationManager.authorizationStatus()
        
        super.init()
        locMgr.delegate=self
        
//        print("init:, CLLocationManager.authorizationStatus()", CLLocationManager.authorizationStatus().rawValue)

        
    }
    
    public func getCurrentLocation(completion: @escaping (String)->() ){
            locMgr.startUpdatingLocation()
            completionLocation=completion //passing fo locmgr delegate method use
    }
    
    
    public func checkLocationStatus(completionGranted: @escaping ()->(), completionDenied: @escaping ()->()){
        
        //TODO: check if .locationServicesEnabled affected by requestWhenInUseAuthorization()
       
        if CLLocationManager.locationServicesEnabled(){
            if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
//                isLocationServicesEnabled = true
                completionGranted()
            }else if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted {
//                isLocationServicesEnabled=false
                completionDenied()
            }else{
                locMgr.requestWhenInUseAuthorization()
                completionAuthGranted = completionGranted
                completionAuthDenied = completionDenied
            }
        }else{
//            isLocationServicesEnabled=false
            completionDenied()
        }
    }
    
    
    //TODO: ambigous with next method
    public func getCityName(location: CLLocation, completion: @escaping (String)->() ){
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: {placemarks, error in
            
            if let e=error {
//                print("--reverseGeocodeLocation() -> error: \(e.localizedDescription)")
                return
            }
            guard let addressDict = placemarks?[0].addressDictionary else {return}
            if let city = addressDict["City"] as? String {
                self.currentCity=city
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
//                print("--reverseGeocodeLocation() -> error: \(e.localizedDescription)")
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
    
   
    
    //CLASS END
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
//        print("**locationManager()->didFailWithError(): \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        //print("didChangeAuthorization, locationStatusInit:", locationStatusInitial.rawValue)
        
        if status == locationStatusInitial { return }
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            self.completionAuthGranted()
//            print("didChangeAuthorization(), completionGranted()")
//            self.isLocationServicesEnabled = true
        }else{
            self.completionAuthDenied()
//            print("didChangeAuthorization(), completionDenied()")
//            self.isLocationServicesEnabled = false
        }
        locationStatusInitial = status
    }
}

