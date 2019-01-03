//
//  WeatherVC.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-11-10.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import UIKit





class WeatherVC: UIViewController {
    
    
    @IBOutlet weak var iv_backgr: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //view current conditions
    @IBOutlet weak var lblCityName: UILabel!
    @IBOutlet weak var lblCurrentTemp: UILabel!
    @IBOutlet weak var lblCurrentTempHigh: UILabel!
    @IBOutlet weak var lblCurrentCondition: UILabel!
    @IBOutlet weak var ivCurrentIcon: UIImageView!
    @IBOutlet weak var lblCurrentTempLow: UILabel!
    @IBOutlet weak var lblCurrentPrecipitaton: UILabel!
    
    
    @IBOutlet weak var viewMiddle: UIView!
    @IBOutlet weak var view24h: UIView!
    @IBOutlet weak var viewDetail: UIView!
    
    
    //@IBOutlet weak var conView24hTop: NSLayoutConstraint!
    //@IBOutlet weak var conView24hBtm: NSLayoutConstraint!
    
    @IBOutlet weak var conViewDetailTop: NSLayoutConstraint!
    //@IBOutlet weak var conViewDetailBtm: NSLayoutConstraint!
    
    @IBOutlet weak var conViewDetailLead: NSLayoutConstraint!
    @IBOutlet weak var conViewDetailTrail: NSLayoutConstraint!
    @IBOutlet weak var conView24Trail: NSLayoutConstraint!
    @IBOutlet weak var conView24Lead: NSLayoutConstraint!
    
    
    
    //view current details
    @IBOutlet weak var lblFeelslike: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWindDirection: UILabel!
    @IBOutlet weak var lblWindSpeed: UILabel!
    
    //TODO: remove?
    @IBOutlet weak var lblCurrentMonth: UILabel!
    
    @IBOutlet weak var viewForecast: UIView!
    
    var locService = LocationService()
    var weatherService = WeatherServiceDarksky()
    var timeStamp:TimeInterval = Date().timeIntervalSince1970
    var unitsType = UnitsHelper.UntitsType.ca
    var u:UnitsHelper.UnitsStrings?
    
    
    
    
    // request counter
    var c = 0

    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        // Do any additional setup after loading the view.
        
        //get current location
        //get city name
        print("interval: \(timeStamp)")
        
        //get locale and set units:
        
        if let countryCode = Locale.current.regionCode {
            if countryCode.contains("US") {
                unitsType = .us
            }else if countryCode.contains("CA"){
                unitsType = .ca
            }else {
                unitsType = .ca
            }
            
            u = UnitsHelper.UnitsStrings(type: unitsType)
            
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        super.viewDidDisappear(true)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        //ui tweaks here
        // set middel view
        //conView24hTop.constant = 0
        conViewDetailTop.constant = -view24h.frame.height
        
        activityIndicator.isHidden = true
        
        //TODO: remove?
//        viewForecast.layer.borderWidth = 2.0
//        viewForecast.layer.borderColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 0.5)
//        lblCurrentMonth.layer.borderColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 0.5)
//        lblCurrentMonth.layer.borderWidth = 2.0
        
        debugPrint("viewDidAppear()...")
        requestLocationWeather()
    }
    
    @IBAction func onTapMore(_ sender: UIButton) {
        toggleView24ViewDetails()
        GfxHelper.animateViewToggle(view: self.view, duration: 0.5, completion: nil)
    }
    
    func toggleView24ViewDetails(){
        if conViewDetailTop.constant == 0 {
           conViewDetailTop.constant = -view24h.frame.height
        }else{
           conViewDetailTop.constant = 0
        }
    }
    
    //extract: recursive view passthrough
    //TODO: remove
    //doesn't make any sense, because uiimage stays the same
    func adjustImages(view: UIView){
        
        for view in view.subviews {
            if let v = view as? UIImageView {
                
                let image = v.image
                let size = CGSize(width: (image?.cgImage?.width)!, height: (image?.cgImage?.height)!)
                if let n = GfxHelper.resizeImage(image: image, size: size) {
                    v.image = n
                }
                
            }
            if view.subviews.count > 0 {
                adjustImages(view: view)
            }
            
        }
        
    }
    
    //TODO: REMOVE DEBUG
    @IBAction func onTapRefresh(_ sender: Any) {
        let bgarray = [#imageLiteral(resourceName: "bg_clear_day"), #imageLiteral(resourceName: "bg_cloudy_day"), #imageLiteral(resourceName: "bg_clear_night"), #imageLiteral(resourceName: "bg_cloudy_night"), #imageLiteral(resourceName: "bg_partially_cloudy_day") ]
        let currentImg = iv_backgr.image
        for i in 0...bgarray.count-1 {
            if currentImg == bgarray[i] {
                i==(bgarray.count-1)  ? (iv_backgr.image = bgarray[0]) : (iv_backgr.image = bgarray[i+1])
                break
            }
        }
        //adjustImages(view: self.view)
    }
    
    
    @IBAction func onTapSearch(_ sender: Any) {
    }
    
    
    
    fileprivate func requestLocationWeather() {
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
       
        
        //get location and city:
        timeStamp = Date().timeIntervalSince1970 //request timestamp
       
        //TODO: remove?
       // let monthDay = UnitsHelper.formatDateMMMMdyyyy(timeInterval: timeStamp)
        //lblCurrentMonth.text = "\(monthDay)"
        
        locService.getCurrentLocation {
            str in
            self.lblCityName.text=str
            
            //after we have location -> getting the weather
            if let loc = self.locService.currentLocation {
                self.weatherService.requestWeather(units: self.unitsType, location: loc, completion: self.updateWeatherDisplay )
            }
        }
    }
    
   
    
    
    func appWillEnterForeground(){
        print("** appWillEnterForeground(): \(c)")
        let stamp2 = Date().timeIntervalSince1970
        let stampDiff = stamp2 - timeStamp
        print("** since last request: \(stampDiff)")
        if stampDiff  <  300 { //5min
            print("interval from last refresh: <300s, no refresh ")
        }else{
            requestLocationWeather()
        }
        c += 1
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    private func updateWeatherDisplay(data: DarkSkyData) {
        
        DispatchQueue.main.async {
            
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
            self.lblCurrentCondition.text = data.summary
            // check for preciptype
            if let pt = data.precipType?.rawValue as? String {
                self.lblCurrentCondition.text = pt
                if data.precipType == DarkSkyData.DSPrecipType.sleet {
                    self.lblCurrentCondition.text = "freezing rain"
                }
            }
            
            self.lblCurrentTemp.text = String(format: "%.0f", data.temperature)+self.u!.tempStr
            self.lblCurrentTempLow.text = String(format: "%.0f", data.temperature)
            
            //self.lblCurrentPrecipitaton =
            
            self.lblFeelslike.text = "\(data.apparentTemperature)"
            self.lblHumidity.text = "\(data.humidity)" + " %"
            self.lblPressure.text = "\(data.pressure)" + self.u!.pressureStr
            self.lblWindSpeed.text = "\(data.windSpeed)" + self.u!.speedStr
            self.lblWindDirection.text = "\( UnitsHelper.convDegreesToCardinal(degrees: data.windBearing) )"
            self.lblVisibility.text = "\(data.visibility)" + self.u!.distanceStr
            
            let img = UIImage(named: "\(data.icon.rawValue)")
            let size = self.ivCurrentIcon.image?.size
            let img2 = GfxHelper.resizeImage(image: img, size: size)
            self.ivCurrentIcon.image = img2
            
            let arr = data.dailyForecast
            //some data for current day from forecast array[0]
            self.lblCurrentTempLow.text = "low: "+String(format: "%.0f", arr[0].dTemperatureLow)
            self.lblCurrentTempHigh.text = "high: "+String(format: "%.0f", arr[0].dTemperatureHigh)
            
            //TODO: background pic
            //sun times for bg pic
            if arr.count>0 {
                let sr = arr[0].dSunrise
                let ss = arr[0].dSunset
                debugPrint("stamp: \(self.timeStamp); sr: \(sr); ss:\(ss)")
                if self.timeStamp > sr && self.timeStamp < ss {
                    //day
                    if data.icon == .clear_day {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_clear_day")
                    }
                    if data.icon == .partly_cloudy_day || data.icon == .wind {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_day")
                    }
                    else {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_cloudy_day")
                    }
                    
                }else {
                    if data.icon == .clear_night {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_clear_night")
                    }
                    else if data.icon == .partly_cloudy_night || data.icon == .wind {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_night")
                    }
                    else {
                        self.iv_backgr.image = #imageLiteral(resourceName: "bg_cloudy_night")
                    }
                }
                
                
            }
        
            // smallest fontsize to set
            var smallestSize:CGFloat = 50.0
            
            // forecast area
            if arr.count >= 6 {
                
                for tag in 1...6 {
                    if let fv = self.view.viewWithTag(tag) as? ForecastView {
                        
                        let day = arr[tag] //( from next day in dataobject ["days"] index==1)
                        let dayName = UnitsHelper.formatDateEMMMdd(timeInterval: day.dTime)
                        fv.lblWeekDayName.text = "\(dayName)"
                        
                        //get smallest fontsize
                        let fontsize = fv.lblWeekDayName.font.pointSize
                        if fontsize < smallestSize {
                            smallestSize = fontsize
                        }
                        
                        //TODO: figure out 24 hr precipitation
                        if let acc = day.dPrecipAccumulation {
                            //we have accumulation in CM (snow 24hrs)
                            //fv.lblPresipitation.text = String(format: "%.0f", acc)+self.u!.precipSnowStr
                            fv.lblPresipitation.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix:"snow", value: acc, unit:self.u!.precipSnowStr)
                        }else{
                            //rain in mm/hr
                            fv.lblPresipitation.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix: "rain", value:day.dPrecipIntensityMax, unit:self.u!.precipRainStr)
                        }
                        
                       // fv.lblTempHigh.text =  String(format: "%.0f", day.dTemperatureHigh)
                        fv.lblTempHigh.text = UnitsHelper.formatTemperatureString(value: day.dTemperatureHigh, unit: "")
                        fv.lblTempLow.text = String(format: "%.0f", day.dTemperatureLow)
                        
                        let im = UIImage(named: "\(day.dIcon)")
                        let sz = (fv.ivIcon.image?.size)!
                        let img = GfxHelper.resizeImage(image: im, size: sz)
                        fv.ivIcon.image = img
                        
                    }
                }
            }
            //end if
            
            //set fonts:
            for tag in 1...6 {
                if let fv = self.view.viewWithTag(tag) as? ForecastView {
                    fv.lblWeekDayName.font.withSize(smallestSize)
                }
                
            }
            
            
            
        }
    }



}





// use collection view ?
class ForecastView: UIView {
    
    
    
    
    @IBOutlet weak var lblWeekDayName: UILabel!
    @IBOutlet weak var lblPresipitation: UILabel!
    @IBOutlet weak var lblTempHigh: UILabel!
    @IBOutlet weak var lblTempLow: UILabel!
    @IBOutlet weak var ivIcon: UIImageView!
    
    
//    override func draw(_ rect: CGRect) {
//        self.layer.borderWidth = 1
//        self.layer.borderColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 0.5)
//
//    }
    
    
    
    
}
