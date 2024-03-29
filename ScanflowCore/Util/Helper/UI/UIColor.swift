//
//  UIColor.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 28/02/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    @nonobjc public class var optiScanBoundingBoxColor: UIColor {
        return UIColor(red: 26 / 255.0, green: 179 / 255.0, blue: 251 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var optiScanMultiBoundingBoxColor: UIColor {
        return UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var optiScanMultiBoundingBoxBackcolor: UIColor {
        return UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 0.3)
    }
    
    @nonobjc public class var optiScanMultiBoundingBoxSelectedBackcolor: UIColor {
        return UIColor(red: 26 / 255.0, green: 179 / 255.0, blue: 251 / 255.0, alpha: 0.3)
    }

    @nonobjc public class var optiScanTickColor: UIColor {
        return UIColor(red: 26 / 255.0, green: 179 / 255.0, blue: 251 / 255.0, alpha: 0.7)
    }

    @nonobjc public class var optiScanMultiBoundingBoxSelectedColor: UIColor {
        return UIColor(red: 26 / 255.0, green: 179 / 255.0, blue: 251 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var topLeftArrowColor: UIColor {
        return UIColor(red: 255 / 255.0, green: 84 / 255.0, blue: 62 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var bottomLeftArrowColor: UIColor {
        return UIColor(red: 53 / 255.0, green: 109 / 255.0, blue: 192 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var topRightArrowColor: UIColor {
        return UIColor(red: 56 / 255.0, green: 105 / 255.0, blue: 232 / 255.0, alpha: 1.0)
    }
    
    @nonobjc public class var bottomRightArrowColor: UIColor {
        return UIColor(red: 255 / 255.0, green: 175 / 255.0, blue: 77 / 255.0, alpha: 1.0)
    }
    
}
