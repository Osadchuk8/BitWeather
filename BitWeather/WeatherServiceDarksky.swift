//
//  WeatherServiceDarksky.swift
//  BitWeather
//
//  Created by Oleksandr on 2018-11-08.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation
import CoreLocation

class WeatherServiceDarksky {
    
    //const
    //TODO: get from plist?
    let baseUrlStr = "https://api.darksky.net/forecast/"
    let apiKey = "519982b83ceb95db10a5d638eee9d5eb"
    
    
    
    // current
    // probably could go into struct:weatherInfo, pass struct later
   
    
 
    
    public func requestWeather(units: UnitsHelper.UnitSystems, location:CLLocation, completionOk: @escaping((DarkSkyTypes.DarkSkyDecodedForecast)->()), completionError: @escaping(()->())){
        var unitsSpec = "?units=auto"
        switch units {
        case .ca:
            unitsSpec = "?units=ca"
        case .us:
            unitsSpec = "?units=us"
        default:
            unitsSpec = "?units=auto"
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let session = URLSession.shared
        let requestStr = ""+baseUrlStr+apiKey+"/"+"\(lat),\(lon)"+unitsSpec
        if let requestUrl = URL(string: requestStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!){
            //print("url:  \(requestUrl.debugDescription)")
            let task = session.dataTask(with: requestUrl){
                (data, response, error) -> () in
                if let _ = error {
                    completionError()
                    //debugPrint("error: \(err.localizedDescription)")
                }else{
                    if let weatherData = data{
                        self.processData(data: weatherData, completion: completionOk)
                    }else{
                        //print("data? == nil ")
                        completionError()
                    }
                    
                }
            };
            task.resume()
        }else{
            //print("wrong URL string: \(requestStr.description)")
        }
        
    }
    
    private func processData(data: Data, completion: @escaping((DarkSkyTypes.DarkSkyDecodedForecast)->())){
        
        
        var decodedForecast = DarkSkyTypes.DarkSkyDecodedForecast()
        
        let jsonRaw = try? JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>  // as! [String, Any]
        
        
         //DS data point obj
        if let c = jsonRaw?["currently"] as? Dictionary<String, Any> {
            
            var current = DarkSkyTypes.Currently()
            if let t = c["time"] as? Double { current.time = t }
            if let s = c["summary"] as? String { current.summary = s }
            if let i = c ["icon"] as? String {
                let ii = i.replacingOccurrences(of: "-", with: "_")
                current.icon = DarkSkyTypes.DSIcons(rawValue: ii) } //enum representation
            if let pi = c["precipIntensity"] as? Double { current.precipIntensity = pi }
            if let pp = c["precipProbability"] as? Double { current.precipProbability = pp }
            if let pt = c["precipType"] as? String {current.precipType = DarkSkyTypes.DSPrecipType(rawValue: pt)}
            if let t = c["temperature"] as? Double { current.temperature = t }
            if let at = c["apparentTemperature"] as? Double { current.apparentTemperature = at}
            if let h = c["humidity"] as? Double { current.humidity = h*100 }
            if let pr = c["pressure"] as? Double { current.pressure = pr }
            if let ws = c["windSpeed"] as? Double { current.windSpeed = ws }
            //windgust
            if let wb = c["windBearing"] as? Double { current.windBearing = wb }
            if let v = c["visibility"] as? Double { current.visibility = v }
            if let cc = c["cloudCover"] as? Double { current.cloudCover = cc }

          //  print("weather data from json: [currently:] \n \(current) ")
            
            decodedForecast.currentlyPoint = current
        }
        
        //DS data block obj
        if let dailyDict = jsonRaw?["daily"] as? Dictionary<String, Any> {
            if let days = dailyDict["data"] as? [Dictionary<String, Any>] {
                
                decodedForecast.dailyBlock = [DarkSkyTypes.Daily]()
                
                for day in days {
                    var d = DarkSkyTypes.Daily()
                    if let t = day["time"] as? Double { d.time = t}
                    if let s = day["summary"] as? String { d.summary = s}
                    if let i = day["icon"] as? String {
                        let ii = i.replacingOccurrences(of: "-", with: "_")
                        d.icon = DarkSkyTypes.DSIcons(rawValue: ii)}  //String representation
                    if let th = day["temperatureHigh"] as? Double { d.temperatureHigh = th}
                    if let tl = day["temperatureLow"] as? Double { d.temperatureLow = tl}
                    if let pp = day["precipProbability"] as? Double { d.precipProbability = pp}
                    if let pm = day["precipIntensityMax"] as? Double { d.precipIntensityMax = pm}
                    if let acc = day["precipAccumulation"] as? Double { d.precipAccumulation = acc}
                    if let sr = day["sunriseTime"] as? Double {d.sunrise = sr}
                    if let ss = day["sunsetTime"] as? Double {d.sunset = ss}
                    if let ws = day["windSpeed"] as? Double { d.windSpeed = ws }
                    //windgust
                    if let wb = day["windBearing"] as? Double { d.windBearing = wb }
                    if let cc = day["cloudCover"] as? Double { d.cloudCover = cc }

                   // print("day block json: \n \(day) ")
                    
                    decodedForecast.dailyBlock?.append(d)
                }
            }
        }
        
        if let hourDict = jsonRaw?["hourly"] as? [String:Any]{
            
            if let summary = hourDict["summary"] as? String {
                decodedForecast.summaryNextHours = summary
            }
            
            if let hours = hourDict["data"] as? [[String:Any]] {
                
                decodedForecast.hourlyBlock = [DarkSkyTypes.Hourly]()
                
                for hour in hours {
                    var hr = DarkSkyTypes.Hourly()
                    if let t = hour["time"] as? Double { hr.time = t }
                    if let s = hour["summary"] as? String { hr.summary = s }
                    if let i = hour["icon"] as? String {
                        let ii = i.replacingOccurrences(of: "-", with: "_")
                        hr.icon = DarkSkyTypes.DSIcons(rawValue: ii) }
                    if let pi = hour["precipIntensity"] as? Double { hr.precipIntensity = pi }
                    if let pp = hour["precipProbability"] as? Double { hr.precipProbability = pp }
                    if let pa = hour["precipAccumulation"] as? Double { hr.precipAccumulation = pa }
                    if let pt = hour["precipType"] as? String { hr.precipType = DarkSkyTypes.DSPrecipType(rawValue: pt) }
                    if let te = hour["temperature"] as? Double { hr.temperature = te }
                    if let ws = hour["windSpeed"] as? Double { hr.windSpeed = ws }
                    if let wb = hour["windBearing"] as? Double { hr.windBearing = wb }
                    if let cc = hour["cloudCover"] as? Double { hr.cloudCover = cc }
                    
                   // print("hr block json: \n \(hr) ")
                    
                    decodedForecast.hourlyBlock?.append(hr)
                    
                }
            }
        }
        
        
        
        completion(decodedForecast)
    }
    
    
    public func evaluateCondition(probability: Double, temp:Double, intensity: Double, accumulation:Double, cover:Double, apiIcon:DarkSkyTypes.DSIcons?, unitSystem: UnitsHelper
        .UnitSystems) -> DarkSkyTypes.Condition {
        var r = DarkSkyTypes.Condition.clear
        //DS API metric units: precipitation intens: mm/hr, accumulation: cm of snow
    
        let intens:Double
        let accum:Double
        let tmp:Double
        
        // equalized intensities  -> mm/hour rain and cm/hour snow
        if unitSystem == .us {
            // inches to mm for hourly tresholds
            intens = intensity * 25.2 //in->mm
            accum = accumulation * 2.5 //in->cm
            tmp = UnitsHelper.convertFarenheit(temp: temp)
        }else{
            // mm tresholds
            intens = intensity
            accum = accumulation
            tmp = temp
        }
        
        switch cover {
        case 0..<0.2: r = .clear
        case 0.2..<0.7: r = .partly_cloudy
        case 0.7...: r = .cloudy
        default: break
        }
        
        
        if apiIcon == .fog { r = .fog }
        else if apiIcon == .wind { r = .wind }
        
        
        //moderate drizzle: 0.5mm (0.04"); heavy drizzle: 1mm(0.04");
        //slight rain: 0.5-1mm (0.02-0.04"); light rain : 1-2mm (0.04"-0.07"); moderate: 2-10mm (0.07-0.4"); heavy: >10 (>0.4")
        //snow: same numbers, but in cm
        
        let isApiPrecip = (apiIcon == .snow || apiIcon == .rain || apiIcon == .sleet)
        
        if isApiPrecip && probability > 0.2 && (accum > 0.2 || intens > 0.2)  {
            r = apiIcon == .sleet ? .sleet : (apiIcon == .rain ? .light_rain : .light_snow )
            if accum > 2 || intens > 2 {
                r = apiIcon == .rain ? .rain :  .snow
            }
            
        }else{
            if probability > 0.8 && !isApiPrecip  {
                if accum > 1 && intens > 1 {
                    r = .sleet
                }else if accum > 1 {
                    r = .snow
                }else if intens > 1 {
                    r = .rain
                }
            }
        }
        
        // freezing rain correction:
        if (r == .rain || r == .light_rain)  && tmp < +3 && accum > 0.0 { r = .freezing_rain }
        
        return r
    }
    
    
    class func formatPrecipString(uStrings: UnitsHelper.UnitsStrings, condition:DarkSkyTypes.Condition, value: Double) -> String {
        var r = ""
        //var valueMM = 0.0
        var isSnow = false
        var unit = ""
        
        if condition == .snow || condition == .light_snow || condition == .sleet {
            unit = uStrings.precipSnowStr
            isSnow = true
        }else{
            unit = uStrings.precipRainStr
            isSnow = false
        }
        
        
        
        if uStrings.sys == .ca {
            if isSnow{
            switch value {
                case 0..<0.2 : r="light flurries"
                case 0.2..<1 : r="snow ~1 "+"\(unit)"
                case 1... : r="snow "+String(format: "%.0f", value)+" \(unit)"
                default: r="snow "+String(format: "%.0f", value)+" \(unit)"
                }
            }else{
                switch value {
                case 0..<1 : r="light rain"
                case 1..<3 : r="rain "+String(format: "%.0f", value)+" \(unit)"
                default: r="rain "+String(format: "%.0f", value)+" \(unit)"
                }
            }
            
        }else{ //us
            if isSnow{
                switch value {
                case 0..<0.2 : r="flurries"
                case 0.2..<1 : r="snow ~1 "+"\(unit)"
                case 1... : r="snow "+String(format: "%.0f", value)+" \(unit)"
                default: r="snow "+String(format: "%.0f", value)+" \(unit)"
                }
            }else{
                switch value {
                case 0..<0.05 : r="drizzle"
                case 0.05..<0.1 : r="rain ~0.1in"
                case 0.1... : r="rain "+String(format: "%.1f", value)+" \(unit)"
                default: r="rain "+String(format: "%.1f", value)+" \(unit)"
                }
            }
        }
        
        if condition == .freezing_rain {
            r = "freezing rain"
        }
        
        return r
        
    }
    
    class func formatTemperatureString(value: Double, unit:String?) -> String {
        if value > 10000 || value < -10000  {return ""}
        let unitStr = unit ?? ""
        let intVal = Int(value)
        //let valStr = String(format: "%.0f", val)
        let  s=( intVal<=0 ? "\(intVal) \(unitStr)" : "+\(intVal) \(unitStr)")
        return s
    }

    
    //CLASS END
}

    public struct DarkSkyTypes {
        
        public enum DSIcons: String {
            //DS Api response string format has "-" separator -> needs to be replaced with matching "_" symbol
            case clear_day, clear_night, rain, snow, sleet, hail, wind, fog, cloudy, partly_cloudy_day, partly_cloudy_night
        }
        
        public enum Condition: String {
            //evaluated condition
            //sleet: snow+rain
            case clear, partly_cloudy, cloudy, fog, wind, light_rain, light_snow, rain, snow, sleet, hail, freezing_rain
        }
        
        public enum DSPrecipType: String {
            case rain, snow, sleet, freezing_rain
        }
        
        public struct DarkSkyDecodedForecast{
            public var currentlyPoint: Currently?
            public var dailyBlock: [Daily]?
            public var hourlyBlock: [Hourly]?
            public var summaryNextHours: String?
        }
        
        public struct Currently{
            // ["currently"] -> [String:Any]
            //currently block doesn't have precipAccumulation field
            public var time = 0.0
            public var summary = ""
            public var icon:DSIcons? = .partly_cloudy_day
            public var precipIntensity = 0.0
            public var precipProbability = 0.0
            public var precipType: DSPrecipType?
            public var temperature = 0.0
            public var apparentTemperature = 0.0
            public var humidity = 0.0
            public var pressure = 0.0
            public var windSpeed = 0.0
            public var windGust = 0.0
            public var windBearing = 0.0
            public var visibility = 0.0
            public var cloudCover = 0.0
        }
        
        
        public struct Daily{
            // ["daily"] -> [[String:Any]]
            public var time = 0.0
            public var summary = ""
            public var icon:DSIcons? = .partly_cloudy_day
            public var temperatureHigh = 0.0
            public var temperatureLow = 0.0
            public var precipProbability = 0.0
            public var precipIntensityMax = 0.0
            public var precipAccumulation = 0.0
            public var precipType : DSPrecipType?
            public var sunrise = 0.0
            public var sunset = 0.0
            public var windSpeed = 0.0
            public var windGust = 0.0
            public var windBearing = 0.0
            public var cloudCover = 0.0
        }
        
        public struct Hourly{
            // ["hourly"] -> [[]String:Any]
            public var time = 0.0
            public var summary = ""
            public var icon:DSIcons? = .partly_cloudy_day
            public var precipIntensity = 0.0
            public var precipProbability = 0.0
            public var precipAccumulation = 0.0  //  snow accumulation: unit per hour
            public var precipType : DSPrecipType?
            public var temperature = 0.0
            public var apparentTemperature = 0.0
            public var windSpeed = 0.0
            public var windGust = 0.0
            public var windBearing = 0.0
            public var cloudCover = 0.0
        }
        
    
}


