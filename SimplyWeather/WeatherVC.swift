//
//  WeatherVC.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-11-10.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import UIKit
import CoreLocation





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
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblSunRise: UILabel!
    @IBOutlet weak var lblSunSet: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    
    
    //TODO: remove
    @IBOutlet weak var conViewDetailLead: NSLayoutConstraint!
    @IBOutlet weak var conViewDetailTrail: NSLayoutConstraint!
    @IBOutlet weak var conView24Trail: NSLayoutConstraint!
    @IBOutlet weak var conView24Lead: NSLayoutConstraint!
    //
    
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var searchContainer: UIView!
    
    @IBOutlet weak var conViewSearchTop: NSLayoutConstraint!
    
    
    //TODO: remove?
    @IBOutlet weak var lblCurrentMonth: UILabel!
    
    @IBOutlet weak var viewForecast: UIView!
    
    var locService = LocationService()
    var weatherService = WeatherServiceDarksky()
    var timeStamp:TimeInterval = Date().timeIntervalSince1970
    var unitSystem = UnitsHelper.UnitSystems.ca
    var currentUnitStrings:UnitsHelper.UnitsStrings?
    var isDark=false
    var condition = DarkSkyTypes.Condition.clear
    
    var searchController:UISearchController = UISearchController()
    
    //TODO: move to service ..
    var customLocation = CLLocation()
    var isCustomLocation = false
    
    // request counter
    var c = 0

    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        //TODO: moving searchViewController to separate citySearchVC
        /*
         
         let citySearchVC = storyboard!.instantiateViewController(withIdentifier: "city_search_vc") as! CitySearchVC
        searchController = UISearchController(searchResultsController: citySearchVC)
        searchController.searchResultsUpdater = citySearchVC
        
        let searchBar = searchController.searchBar
        searchBar.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 0)
        searchContainer.addSubview(searchBar)
        
        self.definesPresentationContext = true
        */
        
        
        //get locale and set units:
        if let countryCode = Locale.current.regionCode {
            if countryCode.contains("US") {
                unitSystem = .us
            }else if countryCode.contains("CA"){
                unitSystem = .ca
            }else {
                unitSystem = .ca
            }
            
            currentUnitStrings = UnitsHelper.UnitsStrings(system: unitSystem)
            
        }
        
        //print("interval: \(timeStamp)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        super.viewDidDisappear(true)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        //ui tweaks here
        conViewSearchTop.constant = -viewSearch.frame.height
        conViewDetailTop.constant = -view24h.frame.height
        activityIndicator.isHidden = true
        debugPrint("viewDidAppear()...")
        requestLocationWeather()
    }
    
    @IBAction func onTapSearch(_ sender: Any) {
        print("onTapSearch()")
        
        let vc = storyboard!.instantiateViewController(withIdentifier: "city_search_vc") as! CitySearchVC
        self.present(vc, animated: true, completion: nil)
        
        //conViewSearchTop.constant = 0
        //GfxHelper.animateViewToggle(view: self.view, duration: 0.5, completion: nil)
    }
    
    @IBAction func onTapSearchDone(_ sender: Any) {
        conViewSearchTop.constant = -80
        GfxHelper.animateViewToggle(view: self.view, duration: 0.2, completion: nil)
    }
    
    @IBAction func onTapExpand(_ sender: UIButton) {
        toggleView24ViewDetails()
        GfxHelper.animateViewToggle(view: self.view, duration: 0.2, completion: nil)
    }
    
    func toggleView24ViewDetails(){
        if conViewDetailTop.constant == 0 {
            //detail view is visible, hiding it:
            conViewDetailTop.constant = -view24h.frame.height
            btnExpandMiddleView.setImage(#imageLiteral(resourceName: "b_arrow_down"), for: .normal)
        }else{
            //deatil view non visible: showing it
            conViewDetailTop.constant = 0
            btnExpandMiddleView.setImage(#imageLiteral(resourceName: "b_arrow_up"), for: .normal)

        }
    }
    
    
    //TODO: REMOVE DEBUG
    @IBAction func onTapRefresh(_ sender: Any) {
        
        let nextVC = storyboard!.instantiateViewController(withIdentifier: "weather_main_vc") as? WeatherMainVC
        self.present(nextVC!, animated: true, completion: nil)
        
        
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
    
    
  
    
    
    
    public func requestLocationWeather() {
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
       
        //get location and city:
        timeStamp = Date().timeIntervalSince1970 //request timestamp
    
        if isCustomLocation {
            debugPrint(customLocation)
            locService.getCityName(location: self.customLocation){
                str in
                self.lblCityName.text=str
                self.weatherService.requestWeather(units: self.unitSystem, location: self.customLocation, completion: self.updateWeatherDisplay )
                
            }
            
        }else{
            locService.getCurrentLocation {
                str in
                self.lblCityName.text=str
                
                //after we have location -> getting the weather
                
                if let loc = self.locService.currentLocation {
                    self.weatherService.requestWeather(units: self.unitSystem, location: loc, completion: self.updateWeatherDisplay )
                }
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

    private func displayCurrentlySection(currently: DarkSkyTypes.Currently){
        // main area
        self.lblCurrentCondition.text = currently.summary
        self.lblCurrentTemp.text = String(format: "%.0f", currently.temperature)+self.currentUnitStrings!.tempStr
        
        var accumulation = 0.0
        
        //TODO: check this accumulation value???
        if let pType = currently.precipType {
            accumulation = (pType == DarkSkyTypes.DSPrecipType.snow) ? 2.0 : 0.0
        }
        let condition = self.weatherService.evaluateCondition(probability: currently.precipProbability, temp: currently.temperature, intensity: currently.precipIntensity, accumulation: accumulation, cover: currently.cloudCover, apiIcon: currently.icon)
        //set current condition
        self.condition = condition
        let windStr = "\( UnitsHelper.convDegreesToCardinal(degrees: currently.windBearing) ) " +
            String(format: "%.0f", currently.windSpeed) + self.currentUnitStrings!.speedStr
        self.displayEvaluatedCondition(isDark: self.isDark, condition: condition, probValue: currently.precipProbability, rainValue: currently.precipIntensity, snowValue: accumulation, windString: windStr, targetIconView: self.ivCurrentIcon, targetPrecipitationLabel: self.lblCurrentConditionDetail)
        
        //details area
        
        self.lblHumidity.text = String(format: "%.0f", currently.humidity) + " %"
        self.lblVisibility.text = String(format: "%.0f", currently.visibility) + self.currentUnitStrings!.distanceStr
        self.lblPressure.text = String(format: "%.0f", currently.pressure) + self.currentUnitStrings!.pressureStr
        self.lblWind.text = windStr
    }
    
     func updateBackgroundDetectDark(dailyBlock: [DarkSkyTypes.Daily]){
        
        
        //detect dark
        if dailyBlock.count>0 {
            let sr = dailyBlock[0].sunrise
            let ss = dailyBlock[0].sunset
            
            //detail sunrise, sunset times
            self.lblSunSet.text = UnitsHelper.dateStrHmma(unixTime: ss)
            self.lblSunRise.text = UnitsHelper.dateStrHmma(unixTime: sr)
            
            self.isDark = (self.timeStamp > sr && self.timeStamp < ss) ? false : true
            debugPrint("stamp: \(self.timeStamp); isDark: \(self.isDark) ; sr: \(sr); ss:\(ss)")
            
            switch self.condition {
            case .clear :
                self.iv_backgr.image = !isDark ?  #imageLiteral(resourceName: "bg_clear_day") : #imageLiteral(resourceName: "bg_clear_night")
            case .partly_cloudy, .wind:
                self.iv_backgr.image = !isDark ?  #imageLiteral(resourceName: "bg_partially_cloudy_day") : #imageLiteral(resourceName: "bg_partially_cloudy_night")
            case .cloudy, .fog, .freezing_rain, .sleet, .rain, .light_rain, .light_snow, .snow, .hail:
                self.iv_backgr.image = !isDark ?  #imageLiteral(resourceName: "bg_cloudy_day") : #imageLiteral(resourceName: "bg_cloudy_night")
            }
        }
        
        self.displayEvaluatedIcon(isDark: self.isDark, condition: self.condition, targetIconView: self.ivCurrentIcon)
        
        // min/max temp from daily[0]
        self.lblCurrentTempLow.text = String(format: "%.0f", dailyBlock[0].temperatureLow)
        self.lblCurrentTempHigh.text = String(format: "%.0f", dailyBlock[0].temperatureHigh)
    
    }
    
    func display6daySection(dailyBlock: [DarkSkyTypes.Daily]){
        if dailyBlock.count >= 6 {
            
            for tag in 1...6 {
                if let fv = self.view.viewWithTag(tag) as? ForecastView {
                    let day = dailyBlock[tag] //( from next day in dataobject ["days"] index==1)
                    let dayName = UnitsHelper.dateStrEMMMdd(timeInterval: day.time)
                    fv.lblWeekDayName.text = "\(dayName)"
                    
                    let wind = "\( UnitsHelper.convDegreesToCardinal(degrees: day.windBearing) ) " +
                        String(format: "%.0f", day.windSpeed) + self.currentUnitStrings!.speedStr
                    let condition = weatherService.evaluateCondition(probability: day.cloudCover, temp: day.temperatureHigh, intensity: day.precipIntensityMax, accumulation: day.precipAccumulation, cover: day.cloudCover, apiIcon: day.icon!)
                    displayEvaluatedCondition(isDark: false, condition: condition, probValue: day.precipProbability, rainValue: day.precipIntensityMax, snowValue: day.precipAccumulation, windString: wind, targetIconView: fv.ivIcon, targetPrecipitationLabel: fv.lblPresipitation)
                    fv.lblTempHigh.text = UnitsHelper.formatTemperatureString(value: day.temperatureHigh, unit: "")
                    fv.lblTempLow.text = UnitsHelper.formatTemperatureString(value: day.temperatureLow, unit: "")
                }
            }
        }
    }
    
    func display24hSection(hourlyBlock: [DarkSkyTypes.Hourly], summary: String?){
        
        self.lblSummaryHourly.text = summary ?? ""
        // next day parts = current (6hrs) + 24 -> min 30 entries
        if hourlyBlock.count < 31 { return }
        //partitioning:
        guard let currentHour =  UnitsHelper.dateIntH(unixTime: hourlyBlock[0].time) else { return }
        var startIndex:Int
        var partTitleArr:[String]
        var darkArr:[Bool]
        
        switch (currentHour){
        case 0...5:
            startIndex = 5 - currentHour + 1
            darkArr = [false, false, true, true]
            partTitleArr = ["morning", "afternoon", "evening", "night"]
        case 06...11:
            startIndex = 11 - currentHour + 1
            darkArr = [false, true, true, false]
            partTitleArr = ["afternoon", "evening", "night", "morning"]
        case 12...17:
            startIndex = 18 - currentHour + 1
            darkArr = [true, true, false, false]
            partTitleArr = ["evening", "night","morning", "afternoon"]
        case 18...23:
            startIndex = 23 - currentHour + 1
            darkArr = [true, false, false, true]
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
                var mSpeed = 0.0
                var mBearing = 0.0
                
                for i in iFirst...iLast {
                    mIntensity += hourlyBlock[i].precipIntensity/6
                    mTemp += hourlyBlock[i].temperature/6
                    mProbability += hourlyBlock[i].precipProbability/6
                    mCover += hourlyBlock[i].cloudCover/6
                    accumulation += hourlyBlock[i].precipAccumulation
                    mSpeed += hourlyBlock[i].windSpeed/6
                    mBearing = hourlyBlock[i].windBearing/6
                }
                
                dqv.lblDayQuaterTitle.text =  partTitleArr[tag-11]
                self.isDark = darkArr[tag-11]
                dqv.lblPartTemp.text = UnitsHelper.formatTemperatureString(value: mTemp, unit: "")
                dqv.lblPartDescr.text = "\(hourlyBlock[iFirst].summary)"
                
                let wind = "\( UnitsHelper.convDegreesToCardinal(degrees: mBearing) ) " +
                    String(format: "%.0f", mSpeed) + self.currentUnitStrings!.speedStr
                
                let condition = self.weatherService.evaluateCondition(probability: mProbability, temp: mTemp, intensity: mIntensity*4, accumulation: accumulation*4, cover: mCover, apiIcon: hourlyBlock[iFirst].icon)
                self.displayEvaluatedCondition(isDark:self.isDark, condition:condition, probValue: mProbability, rainValue:mIntensity, snowValue: accumulation, windString: wind, targetIconView: dqv.ivPartIcon, targetPrecipitationLabel: dqv.lblPartDescr)
                
                //precip peaks display
                let pSet : Set<DarkSkyTypes.Condition> = [.freezing_rain, .light_rain, .light_snow, .rain, .snow, .hail, .sleet ]
                if pSet.contains(condition){
                    var value =  mIntensity; if condition == .snow  || condition == .light_snow { value = accumulation }
                    let level = value / 20 + 0.1
                    let view = dqv.vPartLevel
                    let h = (view?.frame.height)! * CGFloat(level)
                    let w = (view?.frame.width)!
                    
                    let rect = CGRect(x: 0, y: 0, width: w, height: h)
                    let pView = UIView(frame: rect)
                    pView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
                    view?.addSubview(pView)
                }
                
            }
        }
    }
    
    private func updateWeatherDisplay(forecast: DarkSkyTypes.DarkSkyDecodedForecast) {
        
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
            // CURRENTLY
            guard let currently = forecast.currentlyPoint else {return}
            self.displayCurrentlySection(currently: currently)
            
            guard let dailyBlock = forecast.dailyBlock else {return}
            self.updateBackgroundDetectDark(dailyBlock: dailyBlock)
            self.display6daySection(dailyBlock: dailyBlock)
            
            guard let hourlyBlock = forecast.hourlyBlock else {return}
            self.display24hSection(hourlyBlock: hourlyBlock, summary: forecast.summaryNextHours)
            
        }
        
    }
    
    private func displayEvaluatedIcon(isDark:Bool, condition: DarkSkyTypes.Condition, targetIconView: UIImageView){
        
        //icon
        if condition == .clear || condition == .partly_cloudy {
            let img:UIImage?
            if isDark  {
                img = UIImage(named: "\(condition.rawValue)"+"_night")
            }else{
                img = UIImage(named: "\(condition.rawValue)"+"_day")
            }
            targetIconView.image = GfxHelper.scaledImage(image: img, newFrame: targetIconView.frame)
        }else{
            targetIconView.image = GfxHelper.scaledImage(image: UIImage(named: "\(condition.rawValue)"), newFrame: targetIconView.frame)
        }
        
    }

    private func displayEvaluatedCondition(isDark:Bool, condition: DarkSkyTypes.Condition,probValue:Double, rainValue:Double, snowValue:Double, windString:String, targetIconView: UIImageView, targetPrecipitationLabel:UILabel){
        
        displayEvaluatedIcon(isDark: isDark, condition: condition, targetIconView: targetIconView)
       
        switch condition{
        case DarkSkyTypes.Condition.clear, .partly_cloudy, .cloudy, .wind:
            targetPrecipitationLabel.text = "\( String(format: "%0.f",  probValue*100) )%"
        case .fog:
            targetPrecipitationLabel.text = "fog"
        case DarkSkyTypes.Condition.light_rain, .rain, .freezing_rain, .sleet, .light_snow, .snow, .hail:
            let precip = DarkSkyTypes.DSPrecipType(rawValue: condition.rawValue)
            targetPrecipitationLabel.text = "\(UnitsHelper.formatPresipString(uStrings: self.currentUnitStrings!, precipType: precip!, value: rainValue) )"
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
   // @IBOutlet weak var vPrecipLevel: UIView!
    
    
    
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
