//
//  UnitsHelper.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-11-08.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation

class UnitsHelper {
    
    public enum UntitsType:String {
        // only for US locale
        case us
        // rest of the world, presumed to be CA-style metric
        case ca
    }
    
    public struct UnitsStrings {
        
        var tempStr:String
        var speedStr:String
        var precipRainStr:String
        var precipSnowStr:String
        var pressureStr:String
        var distanceStr:String
        
        init(type: UnitsHelper.UntitsType){
            switch type {
            case .us:
                tempStr = "°F"
                speedStr = "mph"
                precipRainStr = "in"
                precipSnowStr = "in"
                pressureStr = "mb"
                distanceStr = "mi"

            case .ca:
                tempStr = "°C"
                speedStr = "km/h"
                precipRainStr = "mm"
                precipSnowStr = "cm"
                pressureStr = "mb"
                distanceStr = "km"
            }
        }
    }
    
    class func formatPresipString(unitsType: UntitsType, prefix:String, value: Double, unit:String) -> String {
        var r = ""
        if unitsType == .ca {
            switch value {
            case 0..<0.5 : r="-"
            case 0.5..<1 : r="\(prefix): <1 \(unit)"
            case 1...2 : r="\(prefix): 1..2  \(unit)"
            case 2... : r="\(prefix): "+String(format: "%.0f", value)+" \(unit)"
            default: r="\(prefix): "+String(format: "%.0f", value)+" \(unit)"
            }
        }
        else{ //us
            switch value {
            case 0..<0.05 : r="-"
            case 0.05..<0.5 : r="\(prefix): <0.5 \(unit)"
            case 0.5...1 : r="\(prefix): 0.5..1 \(unit)"
            case 1... : r="\(prefix): "+String(format: "%.0f", value)+" \(unit)"
            default: r="\(prefix): "+String(format: "%.0f", value)+" \(unit)"
            }
        }
        return r
        
    }
    
    class func formatTemperatureString(value: Double, unit:String?) -> String {
        let unitStr = unit ?? ""
        let valStr = String(format: "%.0f", value)
        let  s=(value<0 ? "\(valStr) \(unitStr)" : "+\(valStr) \(unitStr)")
        return s
    }
    
    class func convertKelvins(temp:Float, isMetric:Bool) -> (Float) {
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
    
    class func convertFarenheit(temp:Float) -> (Float) {
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
    
    class func dateFromUnixTime(utime: Double) -> Date {
        let date = Date(timeIntervalSince1970: utime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        //dateFormatter.timeZone = TimeZone.current
        return date
    }
    
    // date as: "Monday"
    class func formatDateEEEE(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let weekDay = Calendar.current.component(.weekday, from: date) - 1
        let weekDayStr = DateFormatter().weekdaySymbols[weekDay]
        return weekDayStr
    }
    
    // date as: "Monday, Jan 01"
    class func formatDateEMMMdd(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM dd"
        let str = formatter.string(from: date)
        
        return "\(str)"
    }
    
    class func formatDateMMMMdyyyy(timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let str = formatter.string(from: date)
        
        return "\(str)"
    }
    
    
}
