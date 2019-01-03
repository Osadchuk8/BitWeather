//
//  GfxHelper.swift
//  SimplyWeather
//
//  Created by Oleksandr on 2018-12-26.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation
import UIKit

class GfxHelper {
    
    
    class func resizeImage(image: UIImage?, size: CGSize?) -> UIImage? {
        if let img = image, let sz = size {
            UIGraphicsBeginImageContextWithOptions(sz, false, 1.0)
            let rect = CGRect(x: 0, y: 0, width: sz.width, height: sz.height)
            img.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage
        }else {
            return nil
        }
        
    }
    
    
    class func animateViewToggle(view: UIView, duration: Double, completion: (()->())?  ){
        
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveEaseIn, animations: {
            view.layoutIfNeeded()
        }) {(animationComplete) in
            completion?()
        }
    }
    

}
