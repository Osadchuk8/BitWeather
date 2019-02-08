//
//  AppShared.swift
//  PromptlyWeather
//
//  Created by Oleksandr on 2019-01-22.
//  Copyright © 2019 Oleksandr. All rights reserved.
//

import Foundation
import CoreLocation

struct AppShared {
    
    static var isCustomLocation = false
    static var needsRefresh = false
    static var location:CLLocation?
    static var unitSystem:UnitsHelper.UnitSystems?
    static var timeZone:TimeZone?
}
