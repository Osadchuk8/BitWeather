//
//  WeatherServiceDarkskyTests.swift
//  PromptlyWeatherTests
//
//  Created by Oleksandr on 2019-01-11.
//  Copyright © 2019 Oleksandr. All rights reserved.
//

import Foundation

import XCTest
@testable import PromptlyWeather

class WeatherServiceDarkskyTests: XCTestCase {
    
    let service = WeatherServiceDarksky()
    
    
    func testEvaluateCondition(){
        
        let prob = 0.21
        let temp = -10.0
        let inten = 20.0
        let accum = 0.5
        let cover = 0.3
        let icon = DarkSkyTypes.DSIcons.rain
        
        let r = service.evaluateCondition(probability: prob, temp: Double(temp), intensity: inten, accumulation: accum, cover: cover, apiIcon: icon, unitSystem: .ca)
        print("test: r= \(r)")
        let expected = DarkSkyTypes.Condition.freezing_rain
        XCTAssert(r == expected)
        
    }
    
    
}
