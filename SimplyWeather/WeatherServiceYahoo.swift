//
//  WeatherService.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2017-12-10.
//  Copyright © 2017 Oleksandr. All rights reserved.
//

import Foundation

class WeatherServiceYahoo {
    
    public var isMetric:Bool = true
    public var unitTemp = ""
    public var unitDist = ""
    
    public var currentTemp:Float = 0
    public var currentCode:Int = 0
    public var cityName:String = ""
    public var maxTemp = 0
    public var minTemp = 0
    public var description:String = ""

   // public var cPrecip:String = "" unavailable
    public var cWindChill:Float = -1
    public var cHumidity:Int = -1
    public var cVisibility:Float = -1
    public var cPressure:Float = -1
    public var cWindSpeed:Float = -1
    public var cWindDir:Float = -1
    public var cWindCardinal:String = "calm"
    
    
    public var yqlForecastArray = [DailyForecast]()
    
    public var codeId:String = ""
    //private var iconArray:Array<String>
    public var picWeatherMain:String = ""
    
    
  
    private let yahooWeatherKey = "dj0yJmk9TWMwM1dsM3BSbE15JmQ9WVdrOWNFbExlR0Z2Tkc4bWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1lNw"
    private let yahooWeatherBaseUrl = "https://query.yahooapis.com/v1/public/yql?q="
    
    
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
                            debugPrint("\n :: atmosphere",atm)
                            if let hum = Int((atm["humidity"] as? String)!) {
                                self.cHumidity = hum
                            }
                            if var pr = Float((atm["pressure"] as? String)!) {
                                if pr > 2000 { //should be in mb, if > 2000 probably [in mercury] -> [33.86 hpa] server side wrong conversion
                                    pr /= 33.86
                                }
                                self.cPressure = pr
                            }
                            
                            if let vis = Float((atm["visibility"] as? String)!) {
                                self.cVisibility = vis/2
                                print("atm->vis",(atm["visibility"] as? String)!)
                                print("cVisibility: \(cVisibility)")
                            }
                            
                        }
                        
                        if let wnd = ch["wind"] as? [String:Any]{
                            if let speed = Float((wnd["speed"] as? String)!) {
                                self.cWindSpeed = speed
                            }
                            if let dir = Float((wnd["direction"] as? String)!) {
                                self.cWindDir = dir
                                self.cWindCardinal = UnitsHelper.convDegreesToCardinal(degrees: Double(dir))
                            }
                            if let chill = Float((wnd["chill"] as? String)!) {
                                //probably "feels like temperature"
                                //yql always in F, convert for C:
                                if self.isMetric {
                                    self.cWindChill = UnitsHelper.convertFarenheit(temp: chill)
                                }else{
                                    self.cWindChill = chill
                                }
                            }
                        }
                        
                        if let item = ch["item"] as? [String:Any]{
                            
                            if let cond = item["condition"] as? [String:Any]{
                                
                                if let temp = Float((cond["temp"] as? String)!){
                                    self.currentTemp=temp
                                }
                                
                                if let code = Int((cond["code"] as? String)!){
                                    self.currentCode = code
                                    
                                    self.picWeatherMain = getConditionPicName(code: code)
                                
                                }
                                
                                if let txt = cond["text"] as? String{
                                    self.description=txt
                                }
                            }
                            
                            if let forecast = item["forecast"] as? Array<Any>{
//                                print("\n ***forecast \n")
//                                print(forecast)
                                
                                //reset array
                                 self.yqlForecastArray.removeAll()
                                
                                for item in forecast as! [[String:Any]]{
                                    
                                    var dayForecast = DailyForecast()
                                    
                                    if let code = Int((item["code"] as? String)!){
                                        dayForecast.code = code
                                        dayForecast.conditionPicName = getConditionPicName(code: code)
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
                                
                                //get max min temp from first element (should be current day)
                                
                                if let forecast = yqlForecastArray[0] as DailyForecast? {
                                    self.maxTemp = forecast.tempHigh
                                    self.minTemp = forecast.tempLow
                                    print("**** forecast", forecast)
                                }
                            }
                        }
                        
                    }
                }
            }
            
        }
              print("**** weather extraction END *** \n")
       // print(json ?? "nil")
        completion() //bg thread
        
    }
    
    public func getConditionPicName(code:Int)->(String) {
        var str = ""
        
        switch code{
        case 0...2: str="ic_hurricane"
        case 3,4,37...39: str="ic_thunder"
        case 5...8,18,46: str="ic_snow_rain"
        case 9: str="ic_drizzle"
        case 10: str="ic_freezing_rain"
        case 11,12,40:str="ic_showers"
        case 13,14: str="ic_light_snow"
        case 15,16,41...43: str="ic_snow"
        case 17,35: str="ic_hail"
        case 19...22: str="ic_fog"
        case 23...25: str="ic_wind"
        case 26: str="ic_cloudy"
        case 27,28: str="ic_mostly_cloudy" //27day, 28night
        case 29,30,44: str="ic_part_cloudy" // day, night, general
        case 31,32: str="ic_clear" //sunny=day, clear=night
        case 33,34: str="ic_light_clouds" //day,night
        case 36: str="ic_hot" // ????
        case 37,47: str="ic_isolated_thunder"
        case 3200: str="ic_na"
        default:str="ic_na"
            
        }
        
        return str
    }
    
    public func getWeather(city:String, country:String,completion:@escaping ( ()->() ) ) {
        
        if isMetric {
            unitTemp="°C"
            unitDist="km"
        } else {
            unitTemp = "°F"
            unitDist = "mi"
        }
        let yqlstr = "select * from weather.forecast where woeid in (select woeid from geo.places(1) where text='"+city+","+country+"')" + " and u='" + unitTemp + "' "
        
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
}

struct DailyForecast{
    public var conditionPicName = ""
    public var code:Int = 0
    public var dateStr:String = ""
    public var day:String = ""
    public var tempHigh:Int = 0
    public var tempLow:Int = 0
    public var textDescr:String = ""
    
}

