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
    
    //view current conditions
    @IBOutlet weak var lblCityName: UILabel!
    @IBOutlet weak var lblCurrentTemp: UILabel!
    @IBOutlet weak var lblCurrentTempHigh: UILabel!
    @IBOutlet weak var lblCurrentCondition: UILabel!
    @IBOutlet weak var ivCurrentIcon: UIImageView!
    @IBOutlet weak var lblCurrentTempLow: UILabel!
    @IBOutlet weak var lblCurrentPrecipitaton: UILabel!
    
    
    //view current details
    @IBOutlet weak var lblFeelslike: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblVisibility: UILabel!
    @IBOutlet weak var lblPressure: UILabel!
    @IBOutlet weak var lblWindDirection: UILabel!
    @IBOutlet weak var lblWindSpeed: UILabel!
    
    
    @IBOutlet weak var lblCurrentMonth: UILabel!
    
    
    var locService = LocationService()
    var weatherService = WeatherServiceDarksky()
    var timeStamp:TimeInterval = Date().timeIntervalSince1970
    var unitsType = UnitsHelper.UntitsType.ca
    var u:UnitsHelper.UnitsStrings?
    
    
    
    
    // request counter
    var c = 0

    
    //forecast view - subclass UIView() -> end of file
    
    
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

    
    fileprivate func requestLocationWeather() {
        //get location and city:
        timeStamp = Date().timeIntervalSince1970 //request timestamp
        
        let monthDay = UnitsHelper.formatDateMMMMdyyyy(timeInterval: timeStamp)
        lblCurrentMonth.text = "\(monthDay)"
        
        locService.getCurrentLocation {
            str in
            self.lblCityName.text=str
            
            //after we have location -> getting the weather
            if let loc = self.locService.currentLocation {
                self.weatherService.requestWeather(units: self.unitsType, location: loc, completion: self.updateWeatherDisplay )
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        debugPrint("viewDidAppear()...")
        requestLocationWeather()
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
            self.lblCurrentCondition.text = data.summary
            self.lblCurrentTemp.text = String(format: "%.0f", data.temperature)+self.u!.tempStr
            self.lblCurrentTempLow.text = String(format: "%.0f", data.temperature)
            self.lblFeelslike.text = "\(data.apparentTemperature)"
            self.lblHumidity.text = "\(data.humidity)" + " %"
            self.lblPressure.text = "\(data.pressure)" + self.u!.pressureStr
            self.lblWindSpeed.text = "\(data.windSpeed)" + self.u!.speedStr
            self.lblWindDirection.text = "\( UnitsHelper.convDegreesToCardinal(degrees: data.windBearing) )"
            self.lblVisibility.text = "\(data.visibility)" + self.u!.distanceStr
            
            self.ivCurrentIcon.image = UIImage(named: "\(data.icon.rawValue)")
            // public var time = 0.0 << ?
            // public var icon = "" <- process icons
            // public var precipIntensity = 0.0 <- add UI
            // public var precipProbability = 0.0  <- add UI
            //        public var windGust = 0.0  -< ??
            
            let arr = data.dailyForecast
            
            //some data for current day from forecast array[0]
            
            self.lblCurrentTempLow.text = "low: "+String(format: "%.0f", arr[0].dTemperatureLow)
            self.lblCurrentTempHigh.text = "high: "+String(format: "%.0f", arr[0].dTemperatureHigh)
            
            //sun times for bg pic
            if arr.count>0 {
                let sr = arr[0].dSunrise
                let ss = arr[0].dSunset
                debugPrint("stamp: \(self.timeStamp); sr: \(sr); ss:\(ss)")
                if self.timeStamp > sr && self.timeStamp < ss {
                    self.view.backgroundColor = #colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1)
                }
                if self.timeStamp > ss {
                    self.view.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
                }
                if self.timeStamp < sr {
                    self.view.backgroundColor = #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
                }
                
            }
        
            // smallest fontsize to set
            var smallestSize:CGFloat = 50.0
            
            
            if arr.count >= 6 {
                
                for tag in 1...6 {
                    if let fv = self.view.viewWithTag(tag) as? ForecastView {
                        
                        let day = arr[tag] //( from next day in dataobject ["days"] index==1)
                        let dayName = UnitsHelper.formatDateEEEEMMMdd(timeInterval: day.dTime)
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
                        fv.ivIcon.image = UIImage(named: "\(day.dIcon)")
                        
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
    
    
    override func draw(_ rect: CGRect) {
        self.layer.borderWidth = 2
        self.layer.borderColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 0.5)
        
    }
    
    
    
    
}
