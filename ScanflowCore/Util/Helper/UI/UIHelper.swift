//
//  UIHelper.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 28/02/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//
import Foundation
import UIKit

extension String {

  /**This method gets size of a string with a particular font.
   */
  public func size(usingFont font: UIFont) -> CGSize {
    return size(withAttributes: [.font: font])
  }

}

extension UIViewController {
    
    func showToast(message : String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        self.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}



extension CGImage {
    var brightnessValue: Int {
        get {
            guard let imageData = self.dataProvider?.data else { return 0 }
            guard let ptr = CFDataGetBytePtr(imageData) else { return 0 }
            let length = CFDataGetLength(imageData)
            
            var red = 0
            var green = 0
            var blue = 0
            var resolutionCount = 0
            
            for pixel in stride(from: 0, to: length, by: 4) {
                
                red += Int(ptr[pixel])
                green += Int(ptr[pixel + 1])
                blue += Int(ptr[pixel + 2])
                resolutionCount += 1
                
            }
            
            let res = (red + blue + green) / (resolutionCount * 3)
            print(res)
            return res
        }
    }
}
