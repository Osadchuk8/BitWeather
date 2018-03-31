//
//  WeatherMainVC.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-01-09.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation


class WeatherMainVC: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var tempLbl: UILabel!
    @IBOutlet var cityLbl: UILabel!
    @IBOutlet var getBtn: UIButton!
    @IBOutlet var tmpMaxLbl: UILabel!
    @IBOutlet var tmpMinLbl: UILabel!
    
    @IBOutlet var statusLbl: UILabel!
    @IBOutlet var imgIconMain: UIImageView!
    
    @IBOutlet var imgPrecipIcon: UIImageView!
    @IBOutlet var imgPressureIcon: UIImageView!
    @IBOutlet var imgWindIcon: UIImageView!
    @IBOutlet var imgHumidity: UIImageView!
    
    @IBOutlet var precipLbl: UILabel!
    @IBOutlet var pressLbl: UILabel!
    @IBOutlet var windLbl: UILabel!
    @IBOutlet var humLbl: UILabel!
    
    @IBOutlet var weekTableView: UITableView!
    
    @IBOutlet var viewRootView: UIView!
    @IBOutlet var viewBgImage: UIImageView!
    
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let TAG = "**WeatherMainVC::: "
    
    let weather = WeatherService()
    let locationMgr =  CLLocationManager()
    let geoCoder = CLGeocoder()
    var currentCity = ""
    var country = ""
    var msg = ""
    var currentLocation = CLLocation()
    var update_count = 0
    var isConnected = false
    var isBusy = false
    
    weak var timer:Timer?
    
    // weak var countDownTimer:Timer?
    var seconds:Int = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print ("**viewCtrl.viewDidLoad()")
        print("currentCity value=", currentCity)
        
        getBtn.titleLabel?.text = "get weather!"
        
        //check connectivity
        isConnected=ConnectivityService.isConnectedToNetwork()
        
        setBackgrndImage()
        
        //location mgr setup
        locationMgr.delegate=self
        locationMgr.desiredAccuracy=kCLLocationAccuracyKilometer //ok for weather
        
        //probably need only for the 1st launch, to ask user permissions
        // show Alert if location non auth
        self.checkAuth()
        
        //TODO add if locationAuth check results
        if isConnected {
            startSequence()
        }else{
            print ("**not connected..")
            msg="No connection..."
            cityLbl.text = " " + msg
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // print(TAG+" viewWillAppear")
    }
    
    func didFinishLaunchingWithOptions(){
        // her tam!!! never up !
        print ( TAG+" didFinishLaunchingWithOptions()")
    }
    
    func startSequence(){
        //run get locationWeather once:
        getLastKnownLocation()
        processLocationTask(location: currentLocation)
    }
    
    func setBackgrndImage(){
        
        //iPhone 7 native: 750 x 1334px
        //bg image 100%
        
        let date = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        
        print(TAG+"hour=",hour)
        
        var color:UIColor?
        
        if (hour>6&&hour<18) {
            color=UIColor(red:50/255,green:180/255,blue:240/255, alpha:1)
            print(TAG+"daytime!")
            
        }else{
            color=UIColor(red:15/255,green:40/255,blue:70/255, alpha:1)
            print(TAG+"night!")
            
        }
        
        //
        //        var img: UIImage?
        //        if (hour>6&&hour<18) {
        //            img=UIImage(named: "bg_blue_sky_clouds")
        //        }else{
        //            img=UIImage(named: "bg_night_sky_stars")
        //        }
        
        if (color != nil) {
            //bgPhotoView.image = img
            
            // color=UIColor.blue
            viewRootView.backgroundColor=color!
            print(TAG+"color:",color!)
        }
    }
    
    func startIndicator(){
        doInUi {
            self.activityIndicator.startAnimating()
            print(self.TAG + "activityIndicator ON")
        }
    }
    
    func stopIndicator(){
        doInUi {
            self.activityIndicator.stopAnimating()
            print(self.TAG + "activityIndicator OFF")
        }
    }
    
    // to repeat weather retrieving attempt, if issue at 1st try
    func startTimer(){
        seconds = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(WeatherMainVC.onTimer), userInfo: nil, repeats: true)
        print("timer start")
        
    }
    
    func stopTimer(){
        timer?.invalidate()
        // countDownTimer?.invalidate()
        print("timer stop")
    }
    
    func onTimer(){
        stopTimer()
        if !isBusy{
            locationMgr.startUpdatingLocation()
            startSequence()
        }else{
            //skip if ASYNC api still in work
            NSLog("** service busy, skip refresh cycle..")
            startTimer()
        }
    }
    
    
    //lst know location
    func getLastKnownLocation(){
        
        print("**getLastKnownLocation() fired!")
        if let location = locationMgr.location {
            currentLocation = location
            let locCoord = location.coordinate
            print("Last coords = \(locCoord.latitude) \(locCoord.longitude)")
        }else{
            print ("** manager.location?.coordinate ==nil..")
        }
    }
    
    
    //reverse geocode -> address -> weather data
    func processLocationTask(location: CLLocation){
        isBusy=true
        self.startIndicator()
        //var str = ""
        print("**processLocationTask() fired!")
        
        // TODO: this task is async, should listen to completion
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            guard let addressDict = placemarks?[0].addressDictionary else {return}
            
            //ASYNC
            
            print("** start ->reverseGeocodeLocation()!...")
            
            if let city = addressDict["City"] as? String {
                self.currentCity=city
                print ("currentCity=", self.currentCity)
            }
            if let country = addressDict["Country"] as? String {
                self.country = country
                print ("country = ", self.country)
            }
            
            if self.currentCity.characters.count>3 && self.country.characters.count>1 {
                
                print(self.TAG+"**  ->reverseGeocodeLocation() -> ASYNC COMPLETED...")
                //current ASYNCtask completed, now do weather task:
                self.weather.getWeather(city: self.currentCity, country: self.country, completion: {self.onWeatherDataReceived()})
            }else{
                self.msg = "No data available"
            }
            
            print("**.isBusy:: ",self.isBusy)
            //END OF ASYNC TASK
        } )
    }
    
    
    //TODO wire condition arg
    func onWeatherDataReceived(){
        stopIndicator()
        print(TAG + "onWeatherDataReceived()")
        msg=self.currentCity
        redraw()
        isBusy=false
        print("**.isBusy=", isBusy)
        
    }
    
    
    func redraw(){
        doInUi {
            print("==redr== on main thr: ", Thread.isMainThread)
            self.tempLbl.text = " " + String(format: "%.0f", self.weather.currentTemp) + "˚C"
            self.cityLbl.text = " " + self.msg
            self.statusLbl.text = " " + self.weather.description
            self.tmpMaxLbl.text = " " + String(format: "%.0f", self.weather.maxTemp)
            self.tmpMinLbl.text = " " + String(format: "%.0f", self.weather.minTemp)
            
            self.humLbl.text = " " + String(format: "%.0d", self.weather.cHumidity) + "%"
            self.pressLbl.text = " " + String(format: "%.0f", self.weather.cPressure)  + "mBar"
            
            self.windLbl.text = " "+String(format: "%.0f", self.weather.cWindSpeed)+" km/h \n wind"
            self.imgIconMain.image = UIImage(named: self.weather.mainIcon)
            
            self.weekTableView.reloadData()
        }
        
        
        
    }
    
    
    @IBAction func useGetBtn(_ sender: UIButton) {
        startSequence()
    }
    
    func checkAuth(){
        
        switch CLLocationManager.authorizationStatus() {
            
        case .authorizedAlways:
            print("auth::  authorizedAlways")
            //locationMgr.startUpdatingLocation()
            
        case .authorizedWhenInUse:
            print("auth::  authorizedWhenInUse")
            //locationMgr.startUpdatingLocation()
            
        case .notDetermined:
            locationMgr.requestWhenInUseAuthorization()
            print("auth:: notDetermined")
            
        case .restricted:
            print("auth::  restricted")
            
        case .denied:
            print("auth::  denied")
            
        }
    }
    
    
    
    //TODO notification on first OK update, stop update on
    //update location task - non controlled repeat
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        NSLog("**locMgr..didUpdateLocations..: () was called")
        
        if let locValue = (manager.location?.coordinate){
            print("**current Location coord = \(locValue.latitude) \(locValue.longitude)")
            
            locationMgr.stopUpdatingLocation()
            //NSLog("**locationMgr.stopUpdatingLocation() was called")
            
        }else{
            print ("** manager.location?.coordinate === nil..")
        }
        
    }
    
    private func locationManager(manager: CLLocationManager,didChangeAuthorizationStatus status: CLAuthorizationStatus){
        print ("**locMgr:: ..didChangeAuth..status() ")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            print ("**locMgr:: ...status OK ")
        }else{
            print ("**locMgr:: ...NOT authorized ")
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("...error...location error is = \(error.localizedDescription)")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func doInBg(_ block: @escaping ()->Void) {
        DispatchQueue.global(qos: .default).async(execute: block)
    }
    
    func doInUi(_ block: @escaping ()->Void) {
        DispatchQueue.main.async(execute: block)
    }
    
    
}


extension WeatherMainVC: UITableViewDataSource,UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weather.yqlForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "week_cell") as! WeatherTableCell
        
        
        cell.weekDayLbl.text = getDayFromDate(dateStr: weather.yqlForecastArray[indexPath.row].dateStr)
        
        cell.weekPrecipLbl.text = String(weather.yqlForecastArray[indexPath.row].dateStr)
        cell.weekTempMaxLbl.text = String(weather.yqlForecastArray[indexPath.row].tempHigh)
        cell.weekTempMinLbl.text = String(weather.yqlForecastArray[indexPath.row].tempLow)
        cell.weekIconImg.image = UIImage(named: "ic_sun")
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        //cell.textLabel!.text = "path:"+String(indexPath.row)
        //cell.backgroundColor=UIColor.clear
    }
    
    func getDayFromDate(dateStr:String)->String{
        
        let df = DateFormatter()
        df.dateFormat = "dd MM yyyy"
        df.locale = Locale(identifier: "en_US_POSIX")
        if let inDate = df.date(from: dateStr) {
            df.dateFormat="EEEE"
            return df.string(from: inDate)}
        else {
            return ""
        }
        
        //        let c = Calendar.current
        //        let components = c.component(.weekday, from: inDate)
        //        let weekDay = components.weekday
        //
        //        print(weekDay)
        //        return weekDay
        
    }
}

class WeatherTableCell:UITableViewCell {
    
    @IBOutlet var weekDayLbl: UILabel!
    @IBOutlet var weekIconImg: UIImageView!
    @IBOutlet var weekPrecipLbl: UILabel!
    @IBOutlet var weekTempMaxLbl: UILabel!
    @IBOutlet var weekTempMinLbl: UILabel!
    
}
