//
//  PreviewView.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 28/02/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

/**
 The camera frame is displayed on this view.
 */
public class PreviewView: UIView {
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Layer expected is of type VideoPreviewLayer")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return previewLayer.session
        }
        set {
            previewLayer.session = newValue
        }
    }
    
    public override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
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


extension UIView {
    
    func addSubviews(_ views: UIView...) {
        views.forEach{ addSubview($0) }
    }
    
}
