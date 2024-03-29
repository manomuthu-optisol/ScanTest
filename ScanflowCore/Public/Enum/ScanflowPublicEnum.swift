//
//  ScanflowPublicEnum.swift
//  ScanflowBarcodeReader
//
//  Created by Mac-OBS-46 on 02/09/22.
//  Copyright © 2022 Scanflow. All rights reserved.
//

import Foundation
import UIKit
import ObjectiveC

 enum ScanflowDetection {
    case none
}

public enum FUNTIONTYPE: String {
    
    case failedImageUpload = "FAILED-IMAGE-UPLOAD"

    case updateCameraScale = "CAMFEED: UPDATE-CAMERA-SCALE"
    case processResults = "PROCESS-RESULTS"

    case captureOutput = "CAPTURE-OUTPUT"
    case drawRect = "DRAW-RECT"
    case imageSaved = "IMAGE-SAVED"
    case formatResults = "FORMAT-RESULTS"
    case calculateBoundBox = "CALCULATE-BOUND-BOX"
    case longDistance = "LONG-DISTANCE"
    case rotateImage = "ROTATE-IMAGE"
    case drawAfterCalculation = "DRAW-AFTER-CALCULATION"
    
    case runModel = "DETECTION: RUN-MODEL"
    case imageSavedDetection = "DETECTION: IMAGE-SAVED"
    case initializeModel = "DETECTION: INITIALIZE-MODEL"
    case originalCropRect = "DETECTION: ORIGINAL-CROP-RECT"
    case rgbDataFromBuffer = "DETECTION: RGB-DATA-FROM-BUFFER"

    case superResolutionStart = "SR: SUPER-RESOLUTION-STARTED"

}

public enum Scanflow {
    
    public enum UpScale {
        
        static let qrCodeEdgeCorrection = Int32(2)
        static let barCodeEdgeCorrection = Int32(1.5)

    }
    
    public enum Texts {
        
        static let waterMark = "SCANFLOW"
        static let expireAlert = "The Scanflow SDK licence validation failed. \nYour licence key has expired!"
        
    }
    
    
    public enum DebugMode {
        
        static let debugPermissionDenied = "Permission denied"
        static let debugEnableId = "DK0205198887544066622022"
        static let sampleBufferWithTestImages = false
         
    }
    
    public enum Models {
        
        static let superResolutionModel = "Sensifai_SuperResolution_TFLite"
        static let superResolutionModelExtension = "tflite"
        
        static let modelConfidence:Float = 0.25
    }
    
    public enum S3 {
        
        static let s3ReleaseClientName = "DEV"
        
        static let s3BucketUrl = "https://datacenter.scanflow.ai/optiscan/uploadfile"
        
        static let s3FinalPathUrl = "\(s3ReleaseClientName)/"
        
    }
    
}



public enum QRDistance: String {
    case short = "Short Distance"
    case long = "Long Distance"
}

public enum PlayBeepFor {
    case oneOfMany
    case normal
}

public enum FailedImageUseCases: String {
    
    case lowLight = "LowLight"
    case longDistance = "LongDistance"
    
    case weChatQr = "D1"
    case lowLightWeChatQr = "LowLight_D1"
    case lowLightLongDistanceWeChatQr = "LowLight_LongDistance_D1"
    case longDistanceWeChatQr = "LongDistance_D1"

    case zxingBar = "D2"
    case lowLightZxingBar = "LowLight_D2"
    case lowLightLongDistanceZxingBar = "LowLight_LongDistance_D2"
    case longDistanceZxingBar = "LongDistance_D2"

}

///Scan flow model details

@objc public enum ZoomOptions: Int {
    case autoZoom
    case touchToZoom
    case normal
}

public enum BarCodeType {
    
    case unknown
    
    case barCode
    case qrCode
    
    case qrLongDistanceGoodLight
    case qrShortDistanceGoodLight

    case qrShortDistanceLowLight
    case qrLongDistanceLowLight
    
}

@objc public enum ScannerMode: Int {

    case qrcode
    case barcode

    case any
    case oneOfMany
    case batchInventory
    case pivotView

    case tire
    case dotTire

    case containerHorizontal
    case containerVertical

    case docuementScaning
}


@objc public enum OverlayViewApperance: Int {
    case square
    case rectangle
    case hide
    case tire
    case containerHorizantal
    case containerVerticle
    case docuementScaning
}

@objc public enum ResolutionTypes: Int {
    case medium
    case hd1280x720
    case hd1920x1080
    case hd4K3840x2160
    case containerHorizantal
    case containerVerticle
    case docuementScaning
}
