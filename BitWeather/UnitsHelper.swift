//
//  UnitsHelper.swift
//  BitWeather
//
//  Created by Oleksandr on 2018-11-08.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation

class UnitsHelper {
    
    public enum UnitSystems:String {
        // only for US locale
        case us
        // rest of the world, presumed to be CA-style metric
        case ca
        
    }
    
    public struct UnitsStrings {
        var sys: UnitSystems
        var tempStr:String
        var speedStr:String
        var precipRainStr:String
        var precipSnowStr:String
        var pressureStr:String
        var distanceStr:String
        
        init(system: UnitsHelper.UnitSystems){
            switch system {
            case .us:
                sys = .us
                tempStr = "°F"
                speedStr = "mph"
                precipRainStr = "in"
                precipSnowStr = "in"
                pressureStr = "mb"
                distanceStr = "mi"

            case .ca:
                sys = .ca
                tempStr = "°C"
                speedStr = "km/h"
                precipRainStr = "mm"
                precipSnowStr = "cm"
                pressureStr = "mb"
                distanceStr = "km"
                
            }
            
            
        }
    }
    
  
    
    class func convertKelvins(temp:Float, toMetric:Bool) -> (Float) {
        // from K to C or F
        var r:Float = 0
        if toMetric {
            // use centigrade
            r=temp-273
        }else{
            // use farengeit
            r=(9/5)*(temp-273)+32
        }
        return r
    }
    
    class func convertFarenheit(temp:Double) -> (Double) {
        // from F to C
        return (temp-32)*(5/9)
    }
    
    class func convertMetersPerSec(speed:Float, isMetric:Bool) -> (Float) {
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
    
    class func convDegreesToCardinal(degrees:Double) -> (String) {
        //var r=""
        
        let names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let count = names.count
        
        //let dir:Int = remainder(round((degrees/360) * count),count)
        let fl = (degrees/360) * Double(count)
        let ro:Int = Int(fl.rounded())
        var re = ro % count
        if re < 0 {
            re += count
        }
        
        return names[re]
        
    }
    
    class func dateStrFull(utime: Double) -> Date {
        let date = Date(timeIntervalSince1970: utime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        //dateFormatter.timeZone = TimeZone.current
        return date
    }
    
    // date as: "Monday"
    class func dateStrEEEE(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let weekDay = Calendar.current.component(.weekday, from: date) - 1
        let weekDayStr = DateFormatter().weekdaySymbols[weekDay]
        return weekDayStr
    }
    
    //24hrs format HOUR
    class func dateIntH(unixTime: Double) -> Int? {
        let date = Date(timeIntervalSince1970: unixTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "H"
        let str = formatter.string(from: date)
        if let int = Int(str) {
            return int
        }else{
            return nil
        }
    }
    
    class func dateIntHrTimeZone(unixTime: Double, zone: TimeZone) -> Int?{
        let date = Date(timeIntervalSince1970: unixTime)
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.dateFormat = "H"
        let str = formatter.string(from: date)
        if let int = Int(str) {
            return int
        }else{
            return nil
        }
    }
    
    // time as 5:30am
    class func dateStrHmma(unixTime: Double) -> String {
        let date = Date(timeIntervalSince1970: unixTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date)
    }
    
    
    
    // date as: "Monday, Jan 01"
    class func dateStrEMMMdd(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM dd"
        let str = formatter.string(from: date)
        return "\(str)"
    }
    
    //date as January 1, 2001
    class func dateStrMMMMdyyyy(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let str = formatter.string(from: date)
        return "\(str)"
    }
    
    
}
