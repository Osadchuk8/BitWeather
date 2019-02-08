//
//  WeatherVC.swift
//  PromptlyWeather
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
    
    //view Details - expandable
    @IBOutlet weak var viewDetail:  UIView!
    @IBOutlet weak var conViewDetailTop: NSLayoutConstraint!
   
    @IBOutlet weak var lblSummaryHourly: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblSunRise: UILabel!
    @IBOutlet weak var lblSunSet: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    
    @IBOutlet weak var btnGpsLocation: UIButton!
    
    @IBOutlet weak var menuPreferences: UIView!
    @IBOutlet weak var conPreferencesBtm: NSLayoutConstraint!
    @IBOutlet weak var segmControlUnitChoice: UISegmentedControl!
    
    @IBOutlet weak var lblRefreshCover: UILabel!
    
    
    weak var timer:Timer?
   
    var locService = LocationService()
    var weatherService = WeatherServiceDarksky()
    var timeStampLastRefresh:TimeInterval = Date().timeIntervalSince1970
    var apiTime:TimeInterval = Date().timeIntervalSince1970
    var currentUnitStrings:UnitsHelper.UnitsStrings?
    var currentUnitSys:UnitsHelper.UnitSystems = .ca
    var isDark=false
    var condition = DarkSkyTypes.Condition.partly_cloudy
    
    // request counter
    var c = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        setUnitStrings()
        AppShared.needsRefresh = true
        lblRefreshCover.alpha = 1.0
        startRequestTimer()
    }
    
    
    private func setUnitStrings() {
        if let sys = AppShared.unitSystem {
            currentUnitSys = sys
            currentUnitStrings = UnitsHelper.UnitsStrings(system: sys)
        }else{
            print("..#Dbg: Appshared.unitsys is nil (.auto procedure)")
            let sys = getUnitSystem()
            currentUnitSys = sys
            currentUnitStrings = UnitsHelper.UnitsStrings(system: sys)
        }
        
    }
    
    
    fileprivate func getUnitSystem() -> UnitsHelper.UnitSystems{
        if let countryCode = Locale.current.regionCode {
            
            if countryCode.contains("US") {
                return .us
            }else if countryCode.contains("CA"){
                return .ca
            }else {
                return .ca
            }
        }else{
            return .ca
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //ui tweaks here
        
       
        conViewDetailTop.constant = -viewDetail.frame.height
        activityIndicator.isHidden = true
        debugPrint("viewDidAppear()...")
        if AppShared.needsRefresh {
          requestLocationWeather()
        }
        conPreferencesBtm.constant = -menuPreferences.frame.height
        segmControlUnitChoice.backgroundColor = .white
        segmControlUnitChoice.layer.cornerRadius = 4.0
        segmControlUnitChoice.clipsToBounds = true
        
        switch AppShared.unitSystem {
            case .ca? : segmControlUnitChoice.selectedSegmentIndex = 2
            case .us? : segmControlUnitChoice.selectedSegmentIndex = 1
            default: segmControlUnitChoice.selectedSegmentIndex = 0
        }
        
        if AppShared.isCustomLocation {
            btnGpsLocation.isHidden = false
            btnGpsLocation.isEnabled = true
        }else{
            btnGpsLocation.isHidden = true
            btnGpsLocation.isEnabled = false
        }
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        super.viewDidDisappear(true)
    }
    
    
    func startRequestTimer(){
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(timedRequest), userInfo: nil, repeats: true)
    }
    
    func timedRequest(){
        print("..timedRequest()")
        //min interval since last refresh
        
        let stampNow = Date().timeIntervalSince1970
        let diff = stampNow - timeStampLastRefresh
        print("** since last request: \(diff)")
        if diff  <  300 { //5min
            print("interval from last refresh: <300s, no refresh ")
        }else{
            requestLocationWeather()
        }
        //TODO: remove debug
        c += 1
        //<<
        
    }
    
    
    func appWillEnterForeground(){
        print("** appWillEnterForeground(): \(c)")
        timedRequest()
        //ui re-adjustments
        if conViewDetailTop.constant == 0 {
            toggleView24ViewDetails()
        }
        if AppShared.isCustomLocation {
            btnGpsLocation.isHidden = false
            btnGpsLocation.isEnabled = true
        }else{
            btnGpsLocation.isHidden = true
            btnGpsLocation.isEnabled = false
        }
        
    }
    
    @IBAction func onTapSearch(_ sender: Any) {
        print("onTapSearch()")
        let vc = storyboard!.instantiateViewController(withIdentifier: "search_vc") as! SearchVC
        self.present(vc, animated: true, completion: nil)
        
    }
    
    
    @IBAction func onTapExpand(_ sender: UIButton) {
        toggleView24ViewDetails()
        GfxHelper.animateViewToggle(view: self.view, duration: 0.2, completion: nil)
    }
    
    
    func toggleView24ViewDetails(){
        if conViewDetailTop.constant == 0 {
            //detail view is visible, hiding it:
            conViewDetailTop.constant = -viewDetail.frame.height
            btnExpandMiddleView.setImage(#imageLiteral(resourceName: "b_arrow_down"), for: .normal)
        }else{
            //deatil view non visible: showing it
            conViewDetailTop.constant = 0
            btnExpandMiddleView.setImage(#imageLiteral(resourceName: "b_arrow_up"), for: .normal)

        }
    }
    
    @IBAction func onSegmentValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: AppShared.unitSystem = nil
        case 1: AppShared.unitSystem = .us
        case 2: AppShared.unitSystem = .ca
        default: AppShared.unitSystem = nil
        }
        setUnitStrings()
        AppShared.needsRefresh = true
    }
    
    
    
    @IBAction func onTapGpsLocation(_ sender: Any) {
        print("onTapGpsLocation")
        if AppShared.isCustomLocation == true {
            AppShared.isCustomLocation = false
            AppShared.location = nil
            requestLocationWeather()
            btnGpsLocation.isEnabled = false
            btnGpsLocation.isHidden = true
        }
        
    }
    
    
    @IBAction func onTapPreferences(_ sender: Any) {
        print("..D: onTapPreferences() ")
        conPreferencesBtm.constant = 0
        GfxHelper.animateViewToggle(view: self.view, duration: 0.3, completion: nil)
    }
    
    
    @IBAction func onTapPreferencesClose(_ sender: Any) {
        print("..D: onTapPreferencesClose() ")
        conPreferencesBtm.constant = -menuPreferences.frame.height
        GfxHelper.animateViewToggle(view: self.view, duration: 0.3, completion: nil)
        if AppShared.needsRefresh {
            self.requestLocationWeather()
            AppShared.needsRefresh = false
        }
    }
    
  
    
    
    
    public func requestLocationWeather() {
        
        
        if ConnectivityHelper.isConnectedToNetwork(){
            //ok
        } else {
            // network not reachable, alert
            GfxHelper.displayAlert(title: "", msg: "Unable do update the data, please check your internet connection", delegate: self, completion: nil)
            return
        }
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
       
        //get location and city:
        timeStampLastRefresh = Date().timeIntervalSince1970 //request timestamp
        if AppShared.isCustomLocation {
            debugPrint(AppShared.location ?? "")
            
            if let loc = AppShared.location {
                locService.getCityName(location: loc){
                    str in
                    self.lblCityName.text=str
                    self.weatherService.requestWeather(units: self.currentUnitSys, location: loc, completion: self.updateWeatherDisplay )
                }
            }
        }else{
            locService.getCurrentLocation {
                str in
                self.lblCityName.text=str
                if let loc = self.locService.currentLocation {
                    self.weatherService.requestWeather(units: self.currentUnitSys, location: loc, completion: self.updateWeatherDisplay )
                }
            }
        }
      
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
        
        //'currently' snow accumulation (not present in API) -> calibration value added for the evaluateCondition()
        if let pType = currently.precipType {
            accumulation = (pType == DarkSkyTypes.DSPrecipType.snow) ? 1 : 0.0
        }
        let condition = self.weatherService.evaluateCondition(probability: currently.precipProbability, temp: currently.temperature, intensity: currently.precipIntensity, accumulation: accumulation, cover: currently.cloudCover, apiIcon: currently.icon, unitSystem: currentUnitSys)
        //set current condition
        self.condition = condition
        
        print("---CURRENTLY \n API_icon: \(currently.icon), prob: \(currently.precipProbability), intensity: \(currently.precipIntensity), acc: \(accumulation) \n evaluated: \(condition)")
        
        let windStr = "\( UnitsHelper.convDegreesToCardinal(degrees: currently.windBearing) ) " +
            String(format: "%.0f", currently.windSpeed) + self.currentUnitStrings!.speedStr
        self.displayEvaluatedCondition(isDark: self.isDark, condition: condition, probValue: currently.precipProbability, rainValue: currently.precipIntensity, snowValue: accumulation, windString: windStr, targetIconView: self.ivCurrentIcon, targetPrecipitationLabel: self.lblCurrentConditionDetail)
        self.lblCurrentConditionDetail.text = "feels like " + String(format: "%.0f", currently.apparentTemperature)
        
        //details area
        
        self.lblHumidity.text = String(format: "%.0f", currently.humidity) + " %"
        self.lblVisibility.text = String(format: "%.0f", currently.visibility) + self.currentUnitStrings!.distanceStr
        self.lblPressure.text = String(format: "%.0f", currently.pressure) + self.currentUnitStrings!.pressureStr
        self.lblWind.text = windStr
    }
    
     func updateBackgroundDetectDark(dailyBlock: [DarkSkyTypes.Daily]){
        
        
        //detect dark
        if dailyBlock.count>0 {
            //unix time for sunrise/sunset
            let sr = dailyBlock[0].sunrise
            let ss = dailyBlock[0].sunset
            
            //detail sunrise, sunset times
            self.lblSunSet.text = UnitsHelper.dateStrHmma(unixTime: ss)
            self.lblSunRise.text = UnitsHelper.dateStrHmma(unixTime: sr)
            
            self.isDark = (self.timeStampLastRefresh > sr && self.timeStampLastRefresh < ss) ? false : true
            debugPrint("stamp: \(self.timeStampLastRefresh); isDark: \(self.isDark) ; sr: \(sr); ss:\(ss)")
            
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
        var tmpHigh, tmpLow:Double
        if dailyBlock[0].temperatureHigh >= dailyBlock[0].temperatureLow {
            tmpHigh = dailyBlock[0].temperatureHigh
            tmpLow = dailyBlock[0].temperatureLow
        }else {
            tmpLow = dailyBlock[0].temperatureHigh
            tmpHigh = dailyBlock[0].temperatureLow
        }
        self.lblCurrentTempLow.text = WeatherServiceDarksky.formatTemperatureString(value: tmpLow, unit: "")
        self.lblCurrentTempHigh.text = WeatherServiceDarksky.formatTemperatureString(value: tmpHigh, unit: "")
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
                    let condition = weatherService.evaluateCondition(probability: day.cloudCover, temp: day.temperatureHigh, intensity: day.precipIntensityMax, accumulation: day.precipAccumulation, cover: day.cloudCover, apiIcon: day.icon!, unitSystem: currentUnitSys)
                    displayEvaluatedCondition(isDark: false, condition: condition, probValue: day.precipProbability, rainValue: day.precipIntensityMax, snowValue: day.precipAccumulation, windString: wind, targetIconView: fv.ivIcon, targetPrecipitationLabel: fv.lblPresipitation)
                    fv.lblTempHigh.text = WeatherServiceDarksky.formatTemperatureString(value: day.temperatureHigh, unit: "")
                    fv.lblTempLow.text = WeatherServiceDarksky.formatTemperatureString(value: day.temperatureLow, unit: "")
                    
                    print("--D-: day: \(dayName), api: \(day.icon!), evaluate: \(condition) ")
                }
            }
        }
    }
    
    func display24hSection(hourlyBlock: [DarkSkyTypes.Hourly], summary: String?){
    
        self.lblSummaryHourly.text = summary ?? ""
        // next day parts = current (6hrs) + 24 -> min 30 entries
        if hourlyBlock.count < 31 { return }
        //partitioning:
        
        // local hour for the specific location
        let hr:Int?
        if AppShared.isCustomLocation, let zone = AppShared.timeZone {
            hr = UnitsHelper.dateIntHrTimeZone(unixTime: hourlyBlock[0].time, zone: zone)
        }else{
            hr = UnitsHelper.dateIntH(unixTime: hourlyBlock[0].time)
        }
                
        guard let currentHour =  hr else { return }
        var startIndex:Int
        var endIndex:Int
        var firstPartIndex:Int // should be 0...3
        var partTitleArr:[String]
        var darkArr:[Bool]
        
        partTitleArr = ["night", "morning", "afternoon", "evening"]
        darkArr = [true, false, false, true]
        
        let partEndHour = 6 * ( 1 + Int(currentHour/6) ) - 1
        
        if partEndHour - currentHour > 2 {
            // start with current dayPart
            startIndex = 0
            endIndex = partEndHour - currentHour - 1
            firstPartIndex = (currentHour/6) % 4
        }else{
            //start with next dayPart
            startIndex = partEndHour - currentHour
            endIndex = startIndex + 5
            firstPartIndex = (currentHour/6 + 1) % 4
        }
      
        /*
        switch (currentHour){
        case 0...5:
            startIndex = 6 - currentHour
            darkArr = [false, false, true, true]
            partTitleArr = ["morning", "afternoon", "evening", "night"]
        case 06...11:
            startIndex = 12 - currentHour
            darkArr = [false, true, true, false]
            partTitleArr = ["afternoon", "evening", "night", "morning"]
        case 12...17:
            startIndex = 18 - currentHour
            darkArr = [true, true, false, false]
            partTitleArr = ["evening", "night","morning", "afternoon"]
        case 18...23:
            startIndex = 24 - currentHour
            darkArr = [true, false, false, true]
            partTitleArr = ["night", "morning", "afternoon", "evening"]
        default:
            print("hour out of 24hr range...")
            return
        }
        */
        
        print("\n --D-: hour/firstPartIndex: \(currentHour)/\(firstPartIndex)")
        
        for tag in 11...14 {
            if let dqv = self.view.viewWithTag(tag) as? DayQuaterView {
                
                //RESET level bars
                for view in dqv.vPartLevel.subviews {
                    view.removeFromSuperview()
                }
                
                let iFirst = startIndex + ( tag - 11 ) * 6
                let iLast = (tag == 11 && endIndex - startIndex < 5) ? endIndex :  iFirst + 5
                let iPart =  (firstPartIndex + (tag - 11)) % 4 //cycle in 0...3
                var mIntensity = 0.0
                var mTemp = 0.0
                var accumulation = 0.0
                var mProbability = 0.0
                var mCover = 0.0
                var mSpeed = 0.0
                var mBearing = 0.0
                
                var count:Double = 0.0
                
                for i in iFirst...iLast {
                    
                    //precipitation parameters: MAX hourly value within 6hrs
                    if mIntensity < hourlyBlock[i].precipIntensity { mIntensity = hourlyBlock[i].precipIntensity }
                    if mProbability < hourlyBlock[i].precipProbability { mProbability = hourlyBlock[i].precipProbability }
                    
                    print("----prob[\(i)]: \(hourlyBlock[i].precipProbability) || mProbability: \(mProbability)")
                    
                    //summary for 6hrs for snow accumulation
                    accumulation += hourlyBlock[i].precipAccumulation
                    mTemp += hourlyBlock[i].temperature
                    mCover += hourlyBlock[i].cloudCover
                    mSpeed += hourlyBlock[i].windSpeed
                    mBearing = hourlyBlock[i].windBearing
                    
                    count += 1
                    
                }
                accumulation /= 1 //summary for given dayPart for snow accumulation
                mTemp /= count
                mCover /= count
                mSpeed /= count
                mBearing /= count
                

                dqv.lblDayQuaterTitle.text = partTitleArr[iPart]       //partTitleArr[tag-11]
                self.isDark = darkArr[iPart]              //darkArr[tag-11]
                dqv.lblPartTemp.text = WeatherServiceDarksky.formatTemperatureString(value: mTemp, unit: "")
                dqv.lblPartDescr.text = "\(hourlyBlock[iFirst].summary)"
                
                let wind = "\( UnitsHelper.convDegreesToCardinal(degrees: mBearing) ) " +
                    String(format: "%.0f", mSpeed) + self.currentUnitStrings!.speedStr
                
                let condition = self.weatherService.evaluateCondition(probability: mProbability, temp: mTemp, intensity: mIntensity, accumulation: accumulation, cover: mCover, apiIcon: hourlyBlock[iFirst].icon, unitSystem: currentUnitSys)
                
                print("--D-:24H dayPart:\(partTitleArr[iPart]) \t idxs: \(iFirst, iLast)  \t  ")
                print("---24HOUR API_icon: \(hourlyBlock[iFirst].icon), prob: \(mProbability), intensity: \(mIntensity), acc: \(accumulation) evaluated: \(condition) \n")
                
                
                self.displayEvaluatedCondition(isDark:self.isDark, condition:condition, probValue: mProbability, rainValue:mIntensity, snowValue: accumulation, windString: wind, targetIconView: dqv.ivPartIcon, targetPrecipitationLabel: dqv.lblPartDescr)
                
                //precip peaks display
                let snowSet : Set<DarkSkyTypes.Condition> = [.light_snow, .snow, .hail ]
                let rainSet : Set<DarkSkyTypes.Condition> = [.freezing_rain, .light_rain, .rain, .sleet ]
                if snowSet.contains(condition) || rainSet.contains(condition){
                    var value =  mIntensity; if condition == .snow  || condition == .light_snow { value = accumulation }
                    let level = value / 15 + 0.1
                    let view = dqv.vPartLevel
                    let h = (view?.frame.height)! * CGFloat(level)
                    let w = (view?.frame.width)!
                    let yOffset = (view?.frame.height)! - h
                    let rect = CGRect(x: 0, y: yOffset, width: w, height: h)
                    let pView = UIView(frame: rect)
                    pView.backgroundColor =  snowSet.contains(condition) ? #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1) : #colorLiteral(red: 0, green: 0.5895997286, blue: 0.9981202483, alpha: 1)
                    view?.addSubview(pView)
                }
                
            }
        }
    }
    
    private func updateWeatherDisplay(forecast: DarkSkyTypes.DarkSkyDecodedForecast) {
        
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
            if self.lblRefreshCover.alpha > 0 {
                GfxHelper.animateViewFadeOut(view: self.lblRefreshCover, duration: 5.0, completion: nil)
            }
            
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
    
    private func displayEvaluatedIcon(isDark:Bool, condition: DarkSkyTypes.Condition, targetIconView: UIImageView?){
        if condition == .clear || condition == .partly_cloudy {
            let img = isDark ? UIImage(named: "\(condition.rawValue)"+"_night") : UIImage(named: "\(condition.rawValue)"+"_day")
            targetIconView?.image = GfxHelper.scaledImage(image: img, newFrame: targetIconView?.frame)
        }else{
            targetIconView?.image = GfxHelper.scaledImage(image: UIImage(named: "\(condition.rawValue)"), newFrame: targetIconView?.frame)
        }
    }

    private func displayEvaluatedCondition(isDark:Bool, condition: DarkSkyTypes.Condition,probValue:Double, rainValue:Double, snowValue:Double, windString:String, targetIconView: UIImageView?, targetPrecipitationLabel:UILabel?){
        
        displayEvaluatedIcon(isDark: isDark, condition: condition, targetIconView: targetIconView)
       
        switch condition{
        case DarkSkyTypes.Condition.clear, .partly_cloudy, .cloudy, .wind:
            targetPrecipitationLabel?.text = "\( String(format: "%0.f",  probValue*100) )%"
        case .fog:
            targetPrecipitationLabel?.text = "fog"
        case .light_rain, .rain, .freezing_rain:
            targetPrecipitationLabel?.text = "\(WeatherServiceDarksky.formatPrecipString(uStrings: self.currentUnitStrings!, condition: condition, value: rainValue) )"
        case .sleet, .light_snow, .snow, .hail:
            let precip = DarkSkyTypes.DSPrecipType(rawValue: condition.rawValue)
            targetPrecipitationLabel?.text = "\(WeatherServiceDarksky.formatPrecipString(uStrings: self.currentUnitStrings!, condition: condition, value: snowValue) )"
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
