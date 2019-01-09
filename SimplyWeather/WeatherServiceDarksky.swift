//
//  WeatherServiceDarksky.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-11-08.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation
import CoreLocation

class WeatherServiceDarksky {
    
    //const
    //TODO: get from plist?
    let baseUrlStr =  "https://api.darksky.net/forecast/"
    let apiKey = "519982b83ceb95db10a5d638eee9d5eb"
    
    
    
    // current
    // probably could go into struct:weatherInfo, pass struct later
   
    
 
    
    public func requestWeather(units: UnitsHelper.UntitsType, location:CLLocation, completion: @escaping((DarkSkyTypes.DarkSkyDecodedForecast)->())){
        var unitsSpec = "?units=auto"
        switch units {
        case .ca:
            unitsSpec = "?units=ca"
        case .us:
            unitsSpec = "?units=us"
        }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let session = URLSession.shared
        let requestStr = ""+baseUrlStr+apiKey+"/"+"\(lat),\(lon)"+unitsSpec
        if let requestUrl = URL(string: requestStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!){
            debugPrint("url::\(requestUrl.debugDescription)")
            let task = session.dataTask(with: requestUrl){
                (data, response, error) -> () in
                if let err = error {
                    debugPrint("error: \(err.localizedDescription)")
                }else{
                    if let weatherData = data{
                        self.processData(data: weatherData, completion: completion)
                    }else{
                        debugPrint("bad Data (nil) received from endpoint ")
                    }
                    
                }
            };
            task.resume()
        }else{
            debugPrint("wrong URL string: \(requestStr.description)")
        }
        
    }
    
    private func processData(data: Data, completion: @escaping((DarkSkyTypes.DarkSkyDecodedForecast)->())){
        
        
        var decodedForecast = DarkSkyTypes.DarkSkyDecodedForecast()
        
        let jsonRaw = try? JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>  // as! [String, Any]
        
        //debugPrint("** \n \(data.debugDescription)")
        //debugPrint("** \n \(jsonRaw.debugDescription)")
        
         //DS data point obj
        if let c = jsonRaw?["currently"] as? Dictionary<String, Any> {
            
            var current = DarkSkyTypes.Currently()
            if let t = c["time"] as? Double { current.time = t }
            if let s = c["summary"] as? String { current.summary = s }
            if let i = c ["icon"] as? String {
                let ii = i.replacingOccurrences(of: "-", with: "_")
                current.icon = DarkSkyTypes.DSIcons(rawValue: ii)! } //enum representation
            if let pi = c ["precipIntensity"] as? Double { current.precipIntensity = pi }
            if let pp = c ["precipProbability"] as? Double { current.precipProbability = pp }
            if let pt = c ["precipType"] as? String {current.precipType = DarkSkyTypes.DSPrecipType(rawValue: pt)}
            if let t = c ["temperature"] as? Double { current.temperature = t }
            if let at = c["apparentTemperature"] as? Double { current.apparentTemperature = at}
            if let h = c ["humidity"] as? Double { current.humidity = h*100 }
            if let pr = c ["pressure"] as? Double { current.pressure = pr }
            if let ws = c ["windSpeed"] as? Double { current.windSpeed = ws }
            //windgust .. ?
            //
            if let wb = c ["windBearing"] as? Double { current.windBearing = wb }
            if let v = c ["visibility"] as? Double { current.visibility = v }
            if let cc = c["cloudCover"] as? Double { current.cloudCover = cc }

            debugPrint("weather data from json: [currently:] \n \(current.summary) \n \t: \(current.temperature) , hum: \(current.humidity) %")
            
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
                        d.icon = ii}  //String representation
                    if let th = day["temperatureHigh"] as? Double { d.temperatureHigh = th}
                    if let tl = day["temperatureLow"] as? Double { d.temperatureLow = tl}
                    if let pm = day["precipIntensityMax"] as? Double { d.precipIntensityMax = pm}
                    if let acc = day["precipAccumulation"] as? Double { d.precipAccumulation = acc}
                    if let sr = day["sunriseTime"] as? Double {d.sunrise = sr}
                    if let ss = day["sunsetTime"] as? Double {d.sunset = ss}
                    if let cc = day["cloudCover"] as? Double { d.cloudCover = cc }

                    
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
                        hr.icon = ii }
                    if let pi = hour["precipIntencity"] as? Double { hr.precipIntensity = pi }
                    if let pp = hour["precipProbability"] as? Double { hr.precipProbability = pp }
                    if let pa = hour["precipAccumulation"] as? Double { hr.precipAccumulation = pa }
                    if let pt = hour["precipType"] as? String { hr.precipType = DarkSkyTypes.DSPrecipType(rawValue: pt) }
                    if let te = hour["temperature"] as? Double { hr.temperature = te }
                    if let ws = hour["windSpeed"] as? Double { hr.windSpeed = ws }
                    if let wb = hour["windBearing"] as? Double { hr.windBearing = wb }
                    if let cc = hour["cloudCover"] as? Double { hr.cloudCover = cc }
                    
                    decodedForecast.hourlyBlock?.append(hr)
                    
                }
            }
        }
        
        
        
        completion(decodedForecast)
    }
    
    
    public func evaluateCondition(probability: Double, intensity: Double, accumulation:Double, cover:Double) -> DarkSkyTypes.Condition {
        var r = DarkSkyTypes.Condition.clear
        //input : 24hr equal values
        
        if cover <= 0.2 {
            r = .clear
        }else if cover > 0.2 {
            r = .partially_cloudy
        }else if cover > 0.6 {
            r = .cloudy
        }else if probability > 0.2{
            if accumulation > 1 && intensity > 1 {          //cm -> 0.2 inches / 3hrs
                r = .mix
            }else if accumulation > 1 {
                r = .snow
            }else if intensity > 1 {
                r = .rain
            }
        }
        return r
    }
    

    
    //CLASS END
}

public struct DarkSkyTypes {
    
    public enum DSIcons: String {
        //DS Api response string format has "-" separator -> needs to be replaced with matching "_" symbol
        case clear_day, clear_night, rain, snow, sleet, wind, fog, cloudy, partly_cloudy_day, partly_cloudy_night
    }
    
    public enum Condition: String {
        //evaluated condition
        case clear, partially_cloudy, cloudy, small_rain, small_snow, rain, snow, mix, freezing_rain
    }
    
    public enum DSPrecipType: String {
        case rain, snow, sleet
    }
    
    public struct DarkSkyDecodedForecast{
        public var currentlyPoint: Currently?
        public var dailyBlock: [Daily]?
        public var hourlyBlock: [Hourly]?
        public var summaryNextHours: String?
    }
    
    public struct Currently{
        // ["currently"] -> [String:Any]
        public var time = 0.0
        public var summary = ""
        public var icon:DSIcons = .partly_cloudy_day
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
        public var icon = ""
        public var temperatureHigh = 0.0
        public var temperatureLow = 0.0
        public var precipIntensityMax = 0.0
        public var precipAccumulation:Double?
        public var precipType : DSPrecipType?
        public var sunrise = 0.0
        public var sunset = 0.0
        public var cloudCover = 0.0
    }
    
    public struct Hourly{
        // ["hourly"] -> [[]String:Any]
        public var time = 0.0
        public var summary = ""
        public var icon = ""
        public var precipIntensity = 0.0
        public var precipProbability = 0.0
        public var precipAccumulation = 0.0  //  snow accumulation: unit per hour
        public var precipType : DSPrecipType?
        public var temperature = 0.0
        public var apparentTemperature = 0.0
        public var windSpeed = 0.0
        public var windBearing = 0.0
        public var cloudCover = 0.0
    }
    
    
}


