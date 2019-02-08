//
//  WeatherMainVC.swift
//  PromptlyWeather
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
    
   // @IBOutlet var precipLbl: UILabel! // no data in YQL api :(
  
    @IBOutlet weak var lblChill: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWindDir: UILabel!
    @IBOutlet weak var lblWindSpeed: UILabel!
    
    
    @IBOutlet var weekTableView: UITableView!
    @IBOutlet var viewRootView: UIView!
    @IBOutlet var viewBgImage: UIImageView!
    
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    
    @IBOutlet weak var btnAddCity: UIButton!
    
    //SEARCH VIEW
    
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var constrSVTop: NSLayoutConstraint!
    @IBOutlet weak var constrSVBot: NSLayoutConstraint!
    
    
    let TAG = "**WeatherMainVC::: "
    
    //let weather = WeatherServiceYahoo ()
    let weather = WeatherServiceDarksky()
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
    
    
    //SEARCH
    var resultSearchController:UISearchController? = nil
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print ("**viewCtrl.viewDidLoad()")
        print("currentCity value=", currentCity)
        
        getBtn.titleLabel?.text = "get weather!"
        
        //check connectivity
        isConnected=ConnectivityHelper.isConnectedToNetwork()
        
        //someUI
        setBackgrndImage()
        weekTableView.tableFooterView = UIView(frame: .zero)
        
        //hide search
        constrSVTop.constant = -viewSearch.frame.height
       //constrSVBot.constant=400+viewSearch.frame.height
        
        
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
        
        //SEARCH
        let citySearchVC = storyboard!.instantiateViewController(withIdentifier: "city_search_vc") as! CitySearchVC
        resultSearchController = UISearchController(searchResultsController: citySearchVC)
        resultSearchController?.searchResultsUpdater = citySearchVC
        
        let searchBar = resultSearchController!.searchBar
        searchBar.backgroundColor = UIColor.clear
        
        searchBar.sizeToFit()
        searchBar.placeholder = "enter city name"
        
        self.viewSearch.addSubview(searchBar)
        viewSearch.backgroundColor = UIColor.clear
        
        let backBtn = UIButton.init(frame: CGRect.init(x: 10, y: 10, width: 30, height: 30))
        backBtn.backgroundColor = UIColor.yellow
        backBtn.addTarget(self, action: #selector(dismissSearchVC), for: UIControlEvents.allTouchEvents)
        
        viewSearch.addSubview(backBtn)
        
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    
    @IBAction func onTapAddCity(_ sender: Any) {
        //show search
        constrSVTop.constant=22
        //constrSVBot.constant=400
    }
    
    func dismissSearchVC(){
        constrSVTop.constant = -viewSearch.frame.height
    }
    
    
    
    func startSequence(){
        //run get locationWeather once:
        
        //TODO: chain !
        
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
    
    
    // gps -> address -> weather data
    
    func processLocationTask(location: CLLocation){
        isBusy=true
        self.startIndicator()
        //var str = ""
        print("**processLocationTask() fired!")
        
        
     //   weather.requestWeather(location:location, completion: self.onWeatherDataReceived)
        
        // >>  yahoo
        /*
        // TODO: this task is async, .. completion
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
        
        */
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
            
            //TODO units !!!
            /*
            self.tempLbl.text = " " + String(format: "%.0f", self.weather.temperature) + " C"
            self.cityLbl.text = " " + self.msg
            self.statusLbl.text = " " + self.weather.summary
            
            self.lblHumidity.text = " " + String(format: "%.0f", self.weather.humidity) + "%"
            self.lblPressure.text = " " + String(format: "%.0f", self.weather.pressure) + "kPa"
            self.lblWindDir.text = ""+UnitsHelper.convDegreesToCardinal(degrees: self.weather.windBearing)
            print(self.weather.windBearing)
            self.lblWindSpeed.text = " " + String(format: "%.0f", self.weather.windSpeed) + "km/h"
            
            */
            
            // yahoo
            /*
            self.tempLbl.text = " " + String(format: "%.0f", self.weather.currentTemp) + self.weather.unitTemp
            self.cityLbl.text = " " + self.msg
            self.statusLbl.text = " " + self.weather.description
            self.tmpMaxLbl.text = " " + String(format: "%d", self.weather.maxTemp)
            self.tmpMinLbl.text = " " + String(format: "%d", self.weather.minTemp)
            
            self.lblChill.text = " " + String(format: "%.0f", self.weather.cWindChill) + self.weather.unitTemp
            self.lblHumidity.text = " " + String(format: "%.0d", self.weather.cHumidity) + "%"
            self.lblVisibility.text = " " + String(format: "%.0f", self.weather.cVisibility) + self.weather.unitDist
            self.lblPressure.text = " " + String(format: "%.0f", self.weather.cPressure) + "kPa"
            self.lblWindDir.text = " " + self.weather.cWindCardinal
            self.lblWindSpeed.text = " " + String(format: "%.0f", self.weather.cWindSpeed) + self.weather.unitDist+"/h"
            
            self.imgIconMain.image = UIImage(named: self.weather.picWeatherMain)
           */
            
            
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
        return 5
//        print(TAG+"table count::::::",  weather.yqlForecastArray.count )
//        return weather.yqlForecastArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "week_cell") as! WeatherTableCell
        
        
//        cell.weekDayLbl.text = getDayFromDate(dateStr: weather.yqlForecastArray[indexPath.row].dateStr)
//        cell.weekDescrLbl.text = String(weather.yqlForecastArray[indexPath.row].textDescr)
//        cell.weekTempMaxLbl.text = String(weather.yqlForecastArray[indexPath.row].tempHigh)
//        cell.weekTempMinLbl.text = String(weather.yqlForecastArray[indexPath.row].tempLow)
//        cell.weekIconImg.image = UIImage(named: weather.yqlForecastArray[indexPath.row].conditionPicName)
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
            df.dateFormat="EEEEEE, MMM d"
            return df.string(from: inDate)}
        else {
            return ""
        }
    
    }
}

class WeatherTableCell:UITableViewCell {
    
    @IBOutlet var weekDayLbl: UILabel!
    @IBOutlet var weekIconImg: UIImageView!
    @IBOutlet var weekDescrLbl: UILabel!
    @IBOutlet var weekTempMaxLbl: UILabel!
    @IBOutlet var weekTempMinLbl: UILabel!
    
}
