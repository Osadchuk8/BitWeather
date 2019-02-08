//
//  ViewController.swift
//  PromptlyWeather
//
//  Created by Oleksandr on 2017-11-30.
//  Copyright © 2017 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate  {
    
//    
//    @IBOutlet var tempLbl: UILabel!
//    @IBOutlet var cityLbl: UILabel!
//    @IBOutlet var getBtn: UIButton!
//    
//    @IBOutlet var humLbl: UILabel!
//    @IBOutlet var pressLbl: UILabel!
//    
//    @IBOutlet var countDownLbl: UILabel!
//    @IBOutlet var activityIndicator: UIActivityIndicatorView!
//    
//    let TAG = "**ViewCtrl::: "
//    
//    let weather = WeatherService()
//    let locationMgr =  CLLocationManager()
//    let geoCoder = CLGeocoder()
//    var currentCity = ""
//    var msg = ""
//    var currentLocation = CLLocation()
//    var update_count = 0
//    var isConnected = false
//    var isBusy = false
//    
//    weak var timer:Timer?
//    
//    weak var countDownTimer:Timer?
//    var seconds:Int = 0
//    
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        print ("**viewCtrl.viewDidLoad()")
//        print("currentCity value=", currentCity)
//        
//        getBtn.titleLabel?.text = "get weather!"
//       
//        //check connectivity
//        isConnected=ConnectivityService.isConnectedToNetwork()
//       
//        //location mgr setup
//        locationMgr.delegate=self
//        locationMgr.desiredAccuracy=kCLLocationAccuracyKilometer //ok for weather
//        
//        //probably need only for the 1st launch, to ask user permissions
//        // show Alert if location non auth
//        self.checkAuth()
//        
//        //TODO add if locationAuth check results
//        if isConnected {
//            startCycle()
//        }else{
//            print ("**not connected..")
//            msg="No connection..."
//            cityLbl.text = " " + msg
//        }
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//       // print(TAG+" viewWillAppear")
//    }
//    
//    func didFinishLaunchingWithOptions(){
//        // her tam!!! never up !
//        print ( TAG+" didFinishLaunchingWithOptions()")
//    }
//    
//    func startCycle(){
//        //run get locationWeather once:
//        getLastKnownLocation()
//        startTimer()
//    }
//    
//    func startIndicator(){
//        doInUi {
//            self.activityIndicator.startAnimating()
//            print(self.TAG + "activityIndicator ON")
//        }
//        
//
//    }
//    
//    func stopIndicator(){
//        doInUi {
//            self.activityIndicator.stopAnimating()
//            print(self.TAG + "activityIndicator OFF")
//        }
//        
//        
//    }
//
//    
//    func updCountDownDispl(){
//        
//        seconds+=1
//        self.countDownLbl.text = "\(seconds)"
//    }
//    
//    func startTimer(){
//        seconds = 0
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(timeInterval: 40, target: self, selector: #selector(ViewController.onTimer), userInfo: nil, repeats: true)
//        
//        //cound down seconds
//        countDownTimer?.invalidate()
//        countDownTimer =  Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updCountDownDispl), userInfo: nil, repeats: true)
//        
//    
//        print("timer start")
//        
//    }
//    
//    func stopTimer(){
//        timer?.invalidate()
//        countDownTimer?.invalidate()
//        print("timer stop")
//        }
//    
//    func onTimer(){
//        stopTimer()
//        if !isBusy{
//            locationMgr.startUpdatingLocation()
//            getLastKnownLocation()
//        }else{
//            //skip if ASYNC api still in work
//            NSLog("** service busy, skip refresh cycle..")
//        }
//        startTimer()
//    }
//    
//    
//    //lst know location
//    func getLastKnownLocation(){
//        
//        print("**getLastKnownLocation() fired!")
//        if let location = locationMgr.location {
//            currentLocation = location
//            let locCoord = location.coordinate
//            print("Last coords = \(locCoord.latitude) \(locCoord.longitude)")
//            processLocationTask(location: currentLocation)
//        }else{
//            print ("** manager.location?.coordinate ==nil..")
//        }
//    }
    
//    
//    //reverse geocode -> address -> weather data
//    func processLocationTask(location: CLLocation){
//        isBusy=true
//        var str = ""
//        print("**processLocationTask() fired!")
//        
//        // TODO: this task is async, should listen to completion
//        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
//            guard let addressDict = placemarks?[0].addressDictionary else {return}
//        
//            //THIS HAPPENS AFTER (ASYNC BLOCK HERE)
//            print("** start ->reverseGeocodeLocation()!...")
//        
//            if let city = addressDict["City"] as? String {
//                str=city
//                if city.characters.count>3 {
//                    self.currentCity=city
//                    print ("currentCity=", self.currentCity)
//                    print(self.TAG+"**  ->reverseGeocodeLocation() -> ASYNC COMPLETED...")
//                    //current ASYNCtask completed, now do weather task:
//                    self.weather.getWeather(city: self.currentCity, completion: {self.onWeatherDataReceived()})
//                    self.startIndicator()
//                }else{
//                    self.msg = "No data available"
//                }
//            }
//            print("**.isBusy:: ",self.isBusy)
//        //END OF ASYNC TASK
//        } )
//    }
//    
//    
//    //TODO wire condition arg
//    func onWeatherDataReceived(){
//        stopIndicator()
//            print(TAG + "onWeatherDataReceived()")
//            msg=self.currentCity
//            redraw()
//            isBusy=false
//        print("**.isBusy=", isBusy)
//
//    }
//    
//    
//    func redraw(){
//        doInUi {
////            print("==redr== on main thr: ", Thread.isMainThread)
////            self.tempLbl.text = " " + self.weather.currentTemp + "˚C"
////            self.cityLbl.text = " " + self.msg
////            self.humLbl.text = " " + self.weather.cHumidity + "%"
////            self.pressLbl.text = " " + self.weather.cPressure  + "mBar"
//        }
//    }
//    
//    func refresh(){
//        print("==refr== on main thr: ", Thread.isMainThread)
//        self.getLastKnownLocation()
//        self.processLocationTask(location: currentLocation)
//        //redraw() in callback method, triggered by WeatherService
//    }
//    
//    
//    
//    @IBAction func useGetBtn(_ sender: UIButton) {
//       refresh()
//    }
//    
//    func checkAuth(){
//        
//        switch CLLocationManager.authorizationStatus() {
//            
//        case .authorizedAlways:
//            print("auth::  authorizedAlways")
//            //locationMgr.startUpdatingLocation()
//            
//        case .authorizedWhenInUse:
//            print("auth::  authorizedWhenInUse")
//            //locationMgr.startUpdatingLocation()
//
//        case .notDetermined:
//            locationMgr.requestWhenInUseAuthorization()
//            print("auth:: notDetermined")
//            
//        case .restricted:
//            print("auth::  restricted")
//            
//        case .denied:
//            print("auth::  denied")
//            
//        }
//    }
//    
//    
//    
//    //TODO notification on first OK update, stop update on
//    //update location task - non controlled repeat
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        
//        NSLog("**locMgr..didUpdateLocations..: () was called")
//        
//        if let locValue = (manager.location?.coordinate){
//            print("**current Location coord = \(locValue.latitude) \(locValue.longitude)")
//            
//            locationMgr.stopUpdatingLocation()
//            //NSLog("**locationMgr.stopUpdatingLocation() was called")
//            
//        }else{
//            print ("** manager.location?.coordinate === nil..")
//        }
//        
//    }
//    
//    private func locationManager(manager: CLLocationManager,didChangeAuthorizationStatus status: CLAuthorizationStatus){
//        print ("**locMgr:: ..didChangeAuth..status() ")
//        if status == .authorizedAlways || status == .authorizedWhenInUse {
//            manager.startUpdatingLocation()
//            print ("**locMgr:: ...status OK ")
//        }else{
//            print ("**locMgr:: ...NOT authorized ")
//        }
//    }
//    
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("...error...location error is = \(error.localizedDescription)")
//    }
//
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//    
//    func doInBg(_ block: @escaping ()->Void) {
//        DispatchQueue.global(qos: .default).async(execute: block)
//    }
//    
//    func doInUi(_ block: @escaping ()->Void) {
//        DispatchQueue.main.async(execute: block)
//    }
//    
//    
//    
}

