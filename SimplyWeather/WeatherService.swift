//
//  WeatherService.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2017-12-10.
//  Copyright © 2017 Oleksandr. All rights reserved.
//

import Foundation

class WeatherService {
    
    public var isMetric:Bool = true
    public var unitToken = ""
    
    public var currentTemp:Float = 0
    public var cityName:String = ""
    public var maxTemp:Float = 0
    public var minTemp:Float = 0
    public var description:String = ""
    
    public var cHumidity:Int=0
    public var cPressure:Float=0
    public var cPrecip:String = ""
    public var cWindSpeed:Float = 0
    public var cWindDir:Float = 0
    
    public var yqlForecastArray = [DailyForecast]()
    
    public var codeId:String = ""
    //private var iconArray:Array<String>
    public var mainIcon:String = ""
    
    
    // TODO shared config
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/forecast"
    private let openWeatherMapAPIKey = "0d99e987169ff4d3d749e5a55317935b"
    private let yahooWeatherKey = "dj0yJmk9TWMwM1dsM3BSbE15JmQ9WVdrOWNFbExlR0Z2Tkc4bWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lNw"
    private let yahooWeatherBaseUrl = "https://query.yahooapis.com/v1/public/yql?q="
    
    
    //    init(){
    //
    //        iconArray = ["ic_sun","ic_cloud","ic_umbrella","ic_drop"]
    //
    //    }
    
    private func getIconOpenWeather(code:Double){
        
        /*
         icon set Openweather
         200 ... 232 thunder
         300 ... 322 drizzle (light rain)
         500 ... 532 rain
         600 ... 622 snow
         701 ... 781 smog - fog
         800 - clear
         801 ... 804 overcast
         900  ... 999 ?? (disasters ...)
         */
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        print("**:: hour:: "+"\(hour)")
        
        if code<200 {
            mainIcon = "ic_cloud-wind"
        }else if code < 299 {
            mainIcon = "ic_thunder"
        }else if code < 399 {
            mainIcon = "ic_light_rain"
        }else if code < 599 {
            mainIcon = "ic_rain"
        }else if code < 699 {
            mainIcon = "ic_snow"
        }else if code < 799 {
            mainIcon = "ic_mist"
        }else if code < 805 {
            mainIcon = "ic_cloud_overcast"
        }else if code < 999 {
            mainIcon = "ic_tornado"
        }else {
            mainIcon = "ic_cloud-wind"
        }
        if code == 800 {
            if hour > 6 && hour < 18 {
                mainIcon = "ic_sun"
            }else {
                mainIcon = "ic_moon"
            }
        }
    }
    
    public func convert(temp:Float) -> (Float) {
        // from K to C or F
        var r:Float = 0
        if isMetric {
            // use centigrade
            r=temp-273
        }else{
            // use farengeit
            r=(9/5)*(temp-273)+32
        }
        return r
    }
    
    public func convert(speed:Float) -> (Float) {
        // from m/s to kph or mph
        var r:Float = 0
        if isMetric {
            // use centigrade
            r=speed*3.6
        }else{
            // use mph
            r=speed*2.23
        }
        return r
    }
    
    
    private func extractData(weatherData: Data, completion:@escaping ( ()->() ) ) {
        let json = try? JSONSerialization.jsonObject(with: weatherData as Data, options: []) as! Dictionary<String,Any>
        
        
        //Yahoo api json response
        
        
        if json != nil {
            print("====== YAHOO JSON ====== data:: \n")
            
            if let top =  json!["query"] as? [String: Any] {
                if let res = top["results"] as? [String:Any] {
                    if let ch = res["channel"] as? [String:Any] {
                        
                        // data level//
                        if let title = ch["title"] as? String {
                            print(title)
                        }
                        
                        if let units = ch["units"] as? [String:Any] {
                            print(units)
                            if let dist = units["distance"] as? String{
                                print("dist::", dist)
                            }
                        }
                        
                        if let atm = ch["atmosphere"] as? [String:Any]{
                            if let hum = Int((atm["humidity"] as? String)!) {
                                self.cHumidity = hum
                            }
                            if var pr = Float((atm["pressure"] as? String)!) {
                                if pr > 2000 { //should be in mb, if > 2000 probably [in mercury] -> [33.86 hpa] server side wrong conversion
                                    pr /= 33.86
                                }
                                self.cPressure = pr
                            }
                        }
                        
                        if let wnd = ch["wind"] as? [String:Any]{
                            if let speed = Float((wnd["speed"] as? String)!) {
                                self.cWindSpeed = speed
                            }
                            if let dir = Float((wnd["direction"] as? String)!) {
                                self.cWindDir = dir
                            }
                        }
                        
                        
                        
                        if let item = ch["item"] as? [String:Any]{
                            
                            if let cond = item["condition"] as? [String:Any]{
                                if let temp = Float((cond["temp"] as? String)!){
                                    self.currentTemp=temp
                                }
                                if let txt = cond["text"] as? String{
                                    self.description=txt
                                }
                            }
                            
                            if let forecast = item["forecast"] as? Array<Any>{
//                                print("\n ***forecast \n")
//                                print(forecast)
                                for item in forecast as! [[String:Any]]{
                                    
                                    var dayForecast = DailyForecast()
                                    
                                    if let code = Int((item["code"] as? String)!){
                                        dayForecast.code = code
                                    }
                                    if let date = item["date"] as? String{
                                        dayForecast.dateStr = date
                                    }
                                    if let day = item["day"] as? String{
                                        dayForecast.day = day
                                    }
                                    if let th = Int((item["high"] as? String)!){
                                        dayForecast.tempHigh = th
                                    }
                                    if let tl = Int((item["low"] as? String)!){
                                        dayForecast.tempLow = tl
                                    }
                                    if let txt = item["text"] as? String{
                                        dayForecast.textDescr = txt
                                    }
                                    
                                    self.yqlForecastArray.append(dayForecast)
                                }
                            }
                            
                            
                            
                        }
                        
                        
                        
                    }
                }
            }
            
        }
        
        
        /*
         
         //OPENWEATHER
         
         if json != nil {
         if let top =  json!["list"] as? [String: Any] {
    
         if json != nil {
         if let name = json!["name"] as? String {
         cityName = name
         }
         if let main = json!["main"] as? Dictionary<String, Any> {
         if let temp = main["temp"] as? Float {
         currentTemp = convert(temp: temp)
         }
         if let humidity = main["humidity"] as? Int{
         cHumidity = humidity
         }
         if let pressure = main["pressure"] as? Int{
         cPressure =  pressure
         }
         if let tmin = main["temp_min"] as? Float{
         minTemp = convert(temp: tmin)
         }
         if let tmax = main["temp_max"] as? Float{
         maxTemp = convert(temp: tmax)
         }
         }
         
         print("**  trying weather CODES:")
         if let weatherArr = json!["weather"] as? Array<Any> {
         if let weatherCodes = weatherArr[0] as? Dictionary<String,Any>{
         if let descr = weatherCodes["description"] as? String{
         print ("weather DESCRIPTION::", descr)
         description = descr
         }
         if let id = weatherCodes["id"] as? Double{
         print ("weather id::  "+"\(id)")
         codeId = String(id)
         getIcon(code: id)
         }
         }
         }
         if let wind = json!["wind"] as? NSDictionary {
         if let speed = wind["speed"] as? Float{
         cWindSpeed = convert(speed: speed)
         print("windspeed: ", cWindSpeed)
         }
         if let deg = wind["deg"] as? Float{
         cWindDir = deg
         }
         }
         
         */
        print("**** weather extraction END *** \n")
        
      //  print(json ?? "nil")
        
        completion() //bg thread
        
    }
    
    
    //callback be used
    
    //    public func getWeather(city:String, country:String, completion:@escaping ( ()->() ) ) {
    //
    //        let session = URLSession.shared
    //        let str:String="\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)"
    //        print(str)
    //        if let requestUrl = URL(string: str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!){
    //            let dataTask = session.dataTask(with: requestUrl){
    //                (data, response, error) -> Void in
    //                if let error = error {
    //                    //some error on server
    //                    print ("Error:\n\(error)")
    //                }else{
    //                    print("** getWeather->extractData" )
    //                    self.extractData(weatherData: data!, completion: completion)
    //                    // completion()
    //                    // completion will continue on bg thread..
    //                }
    //            };
    //            dataTask.resume()
    //
    //        }else{
    //            print("URL nil ...")
    //        }
    //
    //    }
    
    
    public func getWeather(city:String, country:String,completion:@escaping ( ()->() ) ) {
        
        if isMetric {unitToken="c"} else {unitToken = "f"}
        let yqlstr = "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text='"+city+","+country+"')" + " and u='" + unitToken + "' "
        
        let session = URLSession.shared
        let str:String=yahooWeatherBaseUrl + yqlstr + "&format=json" + "&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="
        //&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
        print(str)
        if let requestUrl = URL(string: str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!){
            let dataTask = session.dataTask(with: requestUrl){
                (data, response, error) -> Void in
                if let error = error {
                    //some error on server
                    print ("Error:\n\(error)")
                }else{
                    print("** getWeather->extractData" )
                    self.extractData(weatherData: data!, completion: completion)
                    // completion()
                    // completion will continue on bg thread..
                }
            };
            dataTask.resume()
            
        }else{
            print("URL nil ...")
        }
    }
    
    
    
    
    
    
    // END ********
}

struct DailyForecast{
    
    public var code:Int = 0
    public var dateStr:String = ""
    public var day:String = ""
    public var tempHigh:Int = 0
    public var tempLow:Int = 0
    public var textDescr:String = ""
    
}
