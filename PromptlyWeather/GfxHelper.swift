//
//  GfxHelper.swift
//  PromptlyWeather
//
//  Created by Oleksandr on 2018-12-26.
//  Copyright © 2018 Oleksandr. All rights reserved.
//

import Foundation
import UIKit

class GfxHelper {
    
    
    class func scaledImage(image: UIImage?, newFrame: CGRect?) -> UIImage? {
        if let i = image, let n = newFrame {
            //keep aspect of original image, max image side = min target side
            let ratio = min(n.width/i.size.width, n.height/i.size.height)
            let size = CGSize(width: i.size.width*ratio, height: i.size.height*ratio)
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0) //scale = 0.0 : keep window pixel scale
            let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            i.draw(in: rect)
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
    
    class func animateViewFadeOut(view: UIView, duration: Double, completion: (()->())? ){
        
        UIView.animate(withDuration: duration, animations: {
            view.layoutIfNeeded()
            view.alpha = 0.0
        }) {(animationComplete) in
            completion?()
        }
        
    }
    
    class func animateViewFadeIn(view: UIView, duration: Double, completion: (()->())? ){
        
        UIView.animate(withDuration: duration, animations: {
            view.layoutIfNeeded()
            view.alpha = 1.0
        }) {(animationComplete) in
            completion?()
        }
        
    }
    
    class func displayAlert(title:String, msg: String, delegate:UIViewController, completion: (()->())? ){
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style:UIAlertActionStyle.default, handler: {
            action in completion?() }))
        delegate.present(alert, animated: true, completion:nil)
    }
    

}
