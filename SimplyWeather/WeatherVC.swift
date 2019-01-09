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
    @IBOutlet weak var lblCurrentConditionDetail: UILabel!
    
    @IBOutlet weak var btnExpandMiddleView: UIButton!
    
    @IBOutlet weak var viewMiddle: UIView! //remove?
    
    
    //view24h
    @IBOutlet weak var view24h: UIView!
   
    //view Details - expandable
    @IBOutlet weak var viewDetail: UIView!
    @IBOutlet weak var conViewDetailTop: NSLayoutConstraint!
   
    
    @IBOutlet weak var lblSummaryHourly: UILabel!
    @IBOutlet weak var lblFeelslike: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    
    
    //TODO: remove
    @IBOutlet weak var conViewDetailLead: NSLayoutConstraint!
    @IBOutlet weak var conViewDetailTrail: NSLayoutConstraint!
    @IBOutlet weak var conView24Trail: NSLayoutConstraint!
    @IBOutlet weak var conView24Lead: NSLayoutConstraint!
    //
    
    
    
    //TODO: remove?
    @IBOutlet weak var lblCurrentMonth: UILabel!
    
    @IBOutlet weak var viewForecast: UIView!
    
    var locService = LocationService()
    var weatherService = WeatherServiceDarksky()
    var timeStamp:TimeInterval = Date().timeIntervalSince1970
    var unitsType = UnitsHelper.UntitsType.ca
    var currentUnits:UnitsHelper.UnitsStrings?
    
    
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
            
            currentUnits = UnitsHelper.UnitsStrings(type: unitsType)
            
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
    
    @IBAction func onTapExpand(_ sender: UIButton) {
        btnExpandMiddleView.imageView?.transform = CGAffineTransform(scaleX: -1,y: 1)
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
    
    
    //TODO: REMOVE DEBUG
    @IBAction func onTapRefresh(_ sender: Any) {
        print("onTapRefresh()")
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
        print("onTapSearch()")
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

    private func updateWeatherDisplay(forecast: DarkSkyTypes.DarkSkyDecodedForecast) {
        
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
            // CURRENTLY
            guard let currently = forecast.currentlyPoint else {return}
            
            self.lblCurrentCondition.text = currently.summary
            self.ivCurrentIcon.image = GfxHelper.scaledImage(image: UIImage(named: "\(currently.icon.rawValue)"), newFrame: self.ivCurrentIcon.frame)
           
            
            //TODO: add condition: (OR) IF freezing AND rain -> set "freezing rain"
            // check for preciptype, precize condition info:
            if let pt = currently.precipType?.rawValue as String? {
                self.lblCurrentCondition.text = pt
                if currently.precipType == DarkSkyTypes.DSPrecipType.sleet {
                    self.lblCurrentCondition.text = "freezing rain"
                    self.ivCurrentIcon.image = GfxHelper.scaledImage(image: UIImage(named: "freezing-rain"), newFrame: self.ivCurrentIcon.frame)
                }
            }
            
            if currently.precipIntensity > 0.2, currently.precipProbability > 0.3 {
                self.lblCurrentConditionDetail.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix: "", value: currently.precipIntensity, unit: self.currentUnits!.precipRainStr)
            }
            self.lblCurrentTemp.text = String(format: "%.0f", currently.temperature)+self.currentUnits!.tempStr
            self.lblCurrentTempLow.text = String(format: "%.0f", currently.temperature)
            self.lblFeelslike.text = "\(currently.apparentTemperature)"
            self.lblHumidity.text = "\(currently.humidity)" + " %"
            self.lblPressure.text = "\(currently.pressure)" + self.currentUnits!.pressureStr
            self.lblWind.text = "\( UnitsHelper.convDegreesToCardinal(degrees: currently.windBearing) ) " + "\(currently.windSpeed)" + self.currentUnits!.speedStr
            self.lblVisibility.text = "\(currently.visibility)" + self.currentUnits!.distanceStr
            
            //DAILY
            guard let daily = forecast.dailyBlock else {return}
            
            //some data for current day from forecast array[0]
            self.lblCurrentTempLow.text = "⬇︎ \t"+String(format: "%.0f", daily[0].temperatureLow)
            self.lblCurrentTempHigh.text = "⬆︎ \t"+String(format: "%.0f", daily[0].temperatureHigh)
            
            //TODO: background pic
            //sun times for bg pic
            if daily.count>0 {
                let sr = daily[0].sunrise
                let ss = daily[0].sunset
                debugPrint("stamp: \(self.timeStamp); sr: \(sr); ss:\(ss)")
                
                switch currently.icon {
                case .clear_day: self.iv_backgr.image = #imageLiteral(resourceName: "bg_clear_day")
                case .clear_night: self.iv_backgr.image = #imageLiteral(resourceName: "bg_clear_night")
                case .partly_cloudy_day: self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_day")
                case .partly_cloudy_night: self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_night")
                case .wind: (self.timeStamp > sr && self.timeStamp < ss) ? (self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_day") ): (self.iv_backgr.image = #imageLiteral(resourceName: "bg_partially_cloudy_night"))
                default: (self.timeStamp > sr && self.timeStamp < ss) ? (self.iv_backgr.image = #imageLiteral(resourceName: "bg_cloudy_day")) : (self.iv_backgr.image = #imageLiteral(resourceName: "bg_cloudy_night"))
                }
                
            }
            
            // forecast area
            if daily.count >= 6 {
                
                for tag in 1...6 {
                    if let fv = self.view.viewWithTag(tag) as? ForecastView {
                        
                        let day = daily[tag] //( from next day in dataobject ["days"] index==1)
                        let dayName = UnitsHelper.dateFromUnixTimeEMMMdd(timeInterval: day.time)
                        fv.lblWeekDayName.text = "\(dayName)"
                        
                        //TODO: figure out 24 hr precipitation
                        if let acc = day.precipAccumulation {
                            //we have accumulation in CM or IN (snow 24hrs)
                            //fv.lblPresipitation.text = String(format: "%.0f", acc)+self.u!.precipSnowStr
                            fv.lblPresipitation.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix:"snow", value: acc, unit:self.currentUnits!.precipSnowStr)
                        }else{
                            //rain in mm/hr or in/hr
                            fv.lblPresipitation.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix: "rain", value:day.precipIntensityMax, unit:self.currentUnits!.precipRainStr)
                        }
                        
                       // fv.lblTempHigh.text =  String(format: "%.0f", day.dTemperatureHigh)
                        fv.lblTempHigh.text = UnitsHelper.formatTemperatureString(value: day.temperatureHigh, unit: "")
                        fv.lblTempLow.text = String(format: "%.0f", day.temperatureLow)
                        
                        let im = UIImage(named: "\(day.icon)")
                        let img = GfxHelper.scaledImage(image: im, newFrame: fv.ivIcon.frame)
                        fv.ivIcon.image = img
                    }
                }
            }
            
            // 6hrs x 4 parts, inclusive: night(00...05), morning(06...11), afternoon(12...17), evening(18...23)
            guard let hourly = forecast.hourlyBlock else { return }
            // next day parts = current (6hrs) + 24 -> min 30 entries
            if hourly.count < 31 { return }
            //partitioning:
            guard let currentHour =  UnitsHelper.hourFromUnixTime(unixTime: hourly[0].time) else { return }
            var startIndex:Int
            var partTitleArr:[String]
            
            switch (currentHour){
            case 0...5:
                startIndex = 5 - currentHour + 1
                partTitleArr = ["morning", "afternoon", "evening", "night"]
            case 06...11:
                startIndex = 11 - currentHour + 1
                partTitleArr = ["afternoon", "evening", "night", "morning"]
            case 12...17:
                startIndex = 18 - currentHour + 1
                partTitleArr = ["evening", "night","morning", "afternoon"]
            case 18...23:
                startIndex = 23 - currentHour + 1
                partTitleArr = ["night", "morning", "afternoon", "evening"]
            default:
                print("hour out of 24hr range...")
                return
            }
            
            for tag in 11...14 {
                if let dqv = self.view.viewWithTag(tag) as? DayQuaterView {
                    let iFirst = startIndex + ( tag - 11 ) * 6
                    let iLast = iFirst + 5
                    
                    var mIntensity = 0.0
                    var mTemp = 0.0
                    var accumulation = 0.0
                    var mProbability = 0.0
                    var mCover = 0.0
                    
                    for i in iFirst...iLast {
                        mIntensity += hourly[i].precipIntensity/6
                        mTemp += hourly[i].temperature/6
                        mProbability += hourly[i].precipProbability/6
                        mCover += hourly[i].cloudCover/6
                        accumulation += hourly[i].precipAccumulation
                    }
                    
                  
                    
                    dqv.lblDayQuaterTitle.text =  partTitleArr[tag-11]
                    dqv.lblPartTemp.text = UnitsHelper.formatTemperatureString(value: mTemp, unit: "")
                    
                    dqv.ivPartIcon.image = GfxHelper.scaledImage(image: UIImage(named: hourly[iFirst].icon), newFrame: dqv.ivPartIcon.frame)
                    dqv.lblPartDescr.text = "\(hourly[iFirst].summary)"
                    
                    print("precipType: \(hourly[iFirst].precipType), accumulation: \(accumulation), mIntensity: \(mIntensity)")
                    
                    
                    if hourly[iFirst].precipType == DarkSkyTypes.DSPrecipType.snow {
                        print("IF: precip: snow")
                        let str = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix: "", value: accumulation, unit: self.currentUnits!.precipSnowStr)
                        print("str: \(str)")
                        dqv.lblPartDescr.text = str
                    }else if hourly[iFirst].precipType == DarkSkyTypes.DSPrecipType.rain {
                        print("IF: precip: rain")
                        dqv.lblPartDescr.text = UnitsHelper.formatPresipString(unitsType: self.unitsType, prefix: "", value: mIntensity, unit: self.currentUnits!.precipRainStr)
                    }
                }
            }
            
        }
    }


//CLASS END
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

class DayQuaterView: UIView {
    
    @IBOutlet weak var lblDayQuaterTitle: UILabel!
    @IBOutlet weak var ivPartIcon: UIImageView!
    @IBOutlet weak var lblPartTemp: UILabel!
    @IBOutlet weak var lblPartDescr: UILabel!
    @IBOutlet weak var vPartLevel: UIView!
}

//EOF
