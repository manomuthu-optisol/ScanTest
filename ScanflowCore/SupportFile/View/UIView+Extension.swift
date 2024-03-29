//
//  UIView+Extension.swift
//  ScanflowCoreFramework
//
//  Created by Mac-OBS-46 on 02/09/22.
//

import UIKit
import AVFoundation

extension UIView {
    
    func addSubviews(_ views: UIView...) {
        views.forEach{ addSubview($0) }
    }
    
}

extension AVCaptureDevice {
    
    var isLocked: Bool {
        do {
            try lockForConfiguration()
            return true
        } catch {
            print(error)
            return false
        }
    }
    func setTorch(enable: Bool) {
       guard hasTorch && isLocked else { return }
        defer { unlockForConfiguration() }
        if enable {
            torchMode = .on
        } else {
            torchMode = .off
        }
    }
    
}
