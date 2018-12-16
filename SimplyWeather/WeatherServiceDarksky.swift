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
    let baseUrlStr =  "https://api.darksky.net/forecast/"
    let apiKey = "519982b83ceb95db10a5d638eee9d5eb"
    
    
    
    // current
    // probably could go into struct:weatherInfo, pass struct later
   
    
 
    
    func requestWeather(units: UnitsHelper.UntitsType, location:CLLocation, completion: @escaping((DarkSkyData)->())){
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
    
    func processData(data: Data, completion: @escaping((DarkSkyData)->())){
        
        var dsd = DarkSkyData()
        let jsonRaw = try? JSONSerialization.jsonObject(with: data, options: []) as! Dictionary<String, Any>  // as! [String, Any]
        
        //debugPrint("** \n \(data.debugDescription)")
        //debugPrint("** \n \(jsonRaw.debugDescription)")
        
         //DS data point obj
        if let c = jsonRaw?["currently"] as? Dictionary<String, Any> {
            if let t = c["time"] as? Double { dsd.time = t }
            if let s = c["summary"] as? String { dsd.summary = s }
            if let i = c ["icon"] as? String {
                let ii = i.replacingOccurrences(of: "-", with: "_")
                dsd.icon = DarkSkyData.DSIcons(rawValue: ii)! } //enum representation
            if let pi = c ["precipIntensity"] as? Double { dsd.precipIntensity = pi }
            if let pp = c ["precipProbability"] as? Double { dsd.precipProbability = pp }
            if let t = c ["temperature"] as? Double { dsd.temperature = t }
            if let at = c["apparentTemperature"] as? Double { dsd.apparentTemperature = at}
            if let h = c ["humidity"] as? Double { dsd.humidity = h*100 }
            if let pr = c ["pressure"] as? Double { dsd.pressure = pr }
            if let ws = c ["windSpeed"] as? Double { dsd.windSpeed = ws }
            //windgust .. ?
            //
            if let wb = c ["windBearing"] as? Double { dsd.windBearing = wb }
            if let v = c ["visibility"] as? Double { dsd.visibility = v }
            debugPrint("weather data from json: [currently:] \n \(dsd.summary) \n \t: \(dsd.temperature) , hum: \(dsd.humidity) %")
        }
        
        //DS data block obj
        if let d = jsonRaw?["daily"] as? Dictionary<String, Any> {
            if let days = d["data"] as? [Dictionary<String, Any>] {
                for day in days {
                    var dayData = DarkSkyData.DayData()
                    if let t = day["time"] as? Double { dayData.dTime = t}
                    if let s = day["summary"] as? String { dayData.dSummary = s}
                    if let i = day["icon"] as? String {
                        let ii = i.replacingOccurrences(of: "-", with: "_")
                        dayData.dIcon = ii}  //String representation
                    if let th = day["temperatureHigh"] as? Double { dayData.dTemperatureHigh = th}
                    if let tl = day["temperatureLow"] as? Double { dayData.dTemperatureLow = tl}
                    if let pm = day["precipIntensityMax"] as? Double { dayData.dPrecipIntensityMax = pm}
                    if let acc = day["precipAccumulation"] as? Double { dayData.dPrecipAccumulation = acc}
                    if let sr = day["sunriseTime"] as? Double {dayData.dSunrise = sr}
                    if let ss = day["sunsetTime"] as? Double {dayData.dSunset = ss}
                    
                    dsd.dailyForecast.append(dayData)
                }
            }
        }
        completion(dsd)
    }
    
}

public struct DarkSkyData {
    
    public enum DSIcons: String {
        case clear_day, clear_night, rain, snow, sleet, wind, fog, cloudy, partly_cloudy_day, partly_cloudy_night
    }
    
    //current
    public var time = 0.0
    public var summary = ""
    public var icon:DSIcons = .partly_cloudy_day
    public var precipIntensity = 0.0
    public var precipProbability = 0.0
    public var temperature = 0.0
    public var apparentTemperature = 0.0
    public var humidity = 0.0
    public var pressure = 0.0
    public var windSpeed = 0.0
    public var windGust = 0.0
    public var windBearing = 0.0
    public var visibility = 0.0
    public var dailyForecast = [DayData]()
    
    //daily forecast
    // ["daily"] / data / [Dictionary<String, Any>]  == [[String:Any]]
    
    public struct DayData{
        public var dTime = 0.0
        public var dSummary = ""
        public var dIcon = ""
        public var dTemperatureHigh = 0.0
        public var dTemperatureLow = 0.0
        public var dPrecipIntensityMax = 0.0
        public var dPrecipAccumulation:Double?
        public var dSunrise = 0.0
        public var dSunset = 0.0
    }
    
    
    
    
    
    
    
}


