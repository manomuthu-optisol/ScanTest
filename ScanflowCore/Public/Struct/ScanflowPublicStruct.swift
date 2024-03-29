//
//  PublicStruct.swift
//  ScanflowBarcodeReader
//
//  Created by Mac-OBS-46 on 02/09/22.
//  Copyright © 2022 Scanflow. All rights reserved.
//

import Foundation
import UIKit

/**
 This structure holds the display parameters for the overlay to be drawon on a detected object.
 */
public struct ObjectOverlay {
    public let name: String
    public let borderRect: CGRect
    public let nameStringSize: CGSize
    public let color: UIColor
    public let font: UIFont

    public init(name: String, borderRect: CGRect, nameStringSize: CGSize, color: UIColor, font: UIFont) {
        self.name = name
        self.borderRect = borderRect
        self.nameStringSize = nameStringSize
        self.color = color
        self.font = font
    }
    
}


public struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init(withImage image: UIImage, forKey key: String) {
        self.key = key
        self.mimeType = "image/jpeg"
        self.filename = "photo\(arc4random()).jpeg"
        
        let data = image.jpegData(compressionQuality: 0.5) ?? Data()
        self.data = data
    }
}

public enum QRType: String {
    case qr = "QR Code"
    case bar = "Bar Code"
    case oneOfMany = "One of many"
    case batchInventry = "Batch Inventry"
}


public struct CodeInfo {
    
    public var codeType: QRType!
    public var distance: QRDistance!
    
    public var orginalImage: UIImage?
    public var brightNessAddedImage: UIImage?
    
    public var croppedQRImage: UIImage?
    public var croppedBARImage: UIImage?

    public var upscaledQRImage: UIImage?
    public var srAppliedQRImage: UIImage?

    public var upscaledBARImage: UIImage?
    public var srAppliedBARImage: UIImage?

    public var decodeFailedQRImage: UIImage?
    public var decodeFailedBARImage: UIImage?
    
    public var useCases: FailedImageUseCases!
    
    public init() {
        
        self.useCases = .weChatQr
        
    }
    
}

///Scan flow settings module handler
///Auto Zoom, Touch to Zoom and other settings will be managed
public struct SFSettings {
         
    ///Zoom settings
    public var zoomMode: ZoomOptions!
    
    public var zoomSettings: ZoomSettings! = ZoomSettings()
    
    public var isDetectionFoundAndDecodeFailed: Bool!
    
    public var noDetectionCount: Int!

    public var isDetectionFound: Bool!

    ///Auto Zoom Details
    public  var isAutoZoomEnabled: Bool!
    
    
    ///Touch to Zoom Details
    public var isTouchToZoomEnabled: Bool!
    
    
    ///Auto Flash Light
    public var enableAutoFlashLight: Bool!
    
    ///Auto Flash Light
    public var enableAutoExposure: Bool!
    
    init() {
        
        self.noDetectionCount = 5
        self.isDetectionFoundAndDecodeFailed = false
        self.isDetectionFound = false
        self.isTouchToZoomEnabled = false
        self.isAutoZoomEnabled = false
        self.zoomMode = .normal
        
        self.enableAutoFlashLight = false
        self.enableAutoExposure = false
        
    }
    
}


public struct ZoomSettings {
    
    public var detectionWithDecodeFailedCount: Int!
    public var currentZoomLevel: CGFloat!
    public var detectionState: DetectionMode
    
    init() {
         
        self.detectionWithDecodeFailedCount = 0
        self.currentZoomLevel = 1.2
        self.detectionState = .none
        
    }
    
}

public enum DetectionMode: String {
    
    case success = "Successful Detection & Decode"
    case failed = "Detection success & Decode Failed"
    case maximumZoom = "Detection success & Decode Failed & Zoom reached above eighty percent"
    case none = "No Detection"

}

public struct SFResultHandler {
    
    var successfulDetectionCount: Int!
    
    var barCodeType: BarCodeType!
    
    var originalImage: UIImage!
    var originalImageTime: String!
    
    var brightnessAppliedImage: UIImage?
    var brightnessAppliedTime: String!
    
    public var resized416Image: UIImage?
    public var resized416Time: String!
    
    
    
    var croppedQRImage: UIImage?
    var croppedQRTime: String!

    var croppedBARImage: UIImage?
    var croppedBARTime: String!
    
    
    
    var superResolutionImage: UIImage?
    var superResolutionTime: String!

    
    
    var upscaledQRImage: UIImage?
    var upscaledQRTime: String!
    
    var upscaledBARImage: UIImage?
    var upscaledBARTime: String!
    
    init() {
                
        self.successfulDetectionCount = 0
        self.barCodeType = .unknown
        
    }
    
}

public struct SFConfig {
    
    public var resetCount:Int = 0
    
    ///Mask details
    public var maskSizeSquare: CGSize = CGSize(width: 300, height: 300)
    public var maskSizeRectangle: CGSize = CGSize(width: 70, height: 350)
    public var maskSizeHorizontalRectangle: CGSize = CGSize(width: 350, height: 90)
    public var maskSizeContainerHorizontal: CGSize = CGSize(width: 350, height: 120)
    public var maskSizeContainerVerticle: CGSize = CGSize(width: 100, height: 300)
    
    public var cornerLength: CGFloat = 20
    public var lineWidth: CGFloat = 3
    public var lineColor: UIColor = .white
    public var lineCap: CAShapeLayerLineCap = .round
    
    ///Zoom factor
    public var lastZoomFactor: CGFloat = 1.2
    public let minimumZoom: CGFloat = 1.2
    public let maximumZoom: CGFloat = 10.0
    public let defaultInitialZoomFactor: CGFloat = 1.2

    
    ///Frame & Edge offset
    public let edgeOffset: CGFloat = 2.0
    public var frameCount: Int = 0
    
    init() {
        
        //self.lastZoomFactor = 1.2
        
    }
    
    
}


public struct ScanflowCoreConfigs {

    public let previewView: UIView
    public let scannerMode: ScannerMode
    public let overlayApperance: OverlayViewApperance
    public var overCropNeed: Bool = false
    public var leftTopArc: UIColor = .topLeftArrowColor
    public var leftDownArc: UIColor = .bottomLeftArrowColor
    public var rightTopArc: UIColor = .topRightArrowColor
    public var rightDownArc: UIColor = .bottomRightArrowColor
    public var locationNeed: Bool = false


    public init(previewView: UIView, scannerMode: ScannerMode, overlayApperance: OverlayViewApperance, overCropNeed: Bool, leftTopArc: UIColor, leftDownArc: UIColor, rightTopArc: UIColor, rightDownArc: UIColor, locationNeed: Bool) {
        self.previewView = previewView
        self.scannerMode = scannerMode
        self.overlayApperance = overlayApperance
        self.overCropNeed = overCropNeed
        self.leftTopArc = leftTopArc
        self.leftDownArc = leftDownArc
        self.rightTopArc = rightTopArc
        self.rightDownArc = rightDownArc
        self.locationNeed = locationNeed
    }

}

