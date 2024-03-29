//
//  SFManager+Extension.swift
//  ScanflowCoreFramework
//
//  Created by Mac-OBS-46 on 02/09/22.
//

import Foundation
import Vision
import opencv2
import UIKit
import CoreVideo
//import AppCenterAnalytics

extension SFManager {
    
    
    /// Brightness Value from native
    /// - Parameter sampleBuffer:CMSampleBuffer
    /// - Returns: Double
    public func getBrightnessValue(_ sampleBuffer: CMSampleBuffer) -> Double {
        
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        guard let brightnessValue = exifData?[kCGImagePropertyExifBrightnessValue as String] as? Double else {
            return 0
        }
        return brightnessValue
        
    }
    
    /// Brightness Value from opencv
    /// - Parameter sampleBuffer: CVPixelBuffer
    /// - Returns: Scalar
    public func getBrightnessValueFromOpenCV(_ sampleBuffer: CVPixelBuffer) -> Scalar {
        
        let image = Mat(uiImage: sampleBuffer.toImage())
        
        Imgproc.cvtColor(src: image, dst: image, code: .COLOR_BGR2HLS)
        
        let brightnessValue = opencv2.Core.mean(src: image)
      
        return brightnessValue
        
    }
    
    
    /// Extract QR Code
    /// - Parameter frame: CVImageBuffer
    /// - Returns: Payload & Symbology
    public func extractQRCode(fromFrame frame: CVImageBuffer?) -> (String?, String?) {
        
        guard let validPixelBuffer = frame else {
            return (nil, nil)
        }
        
        let barcodeRequest = VNDetectBarcodesRequest()

        
        try? self.sequenceHandler.perform([barcodeRequest], on: validPixelBuffer)
        guard let results = barcodeRequest.results,
                let firstBarcode = results.first?.payloadStringValue ,
              let symbology = results.first?.symbology.rawValue else {
            return (nil, nil)
        }
        
        return (firstBarcode, symbology)
        
    }
    

    /// Debug Print
    /// - Parameters:
    ///   - message: String
    ///   - function: FUNTIONTYPE
    public func print(message: String, function: FUNTIONTYPE) {
         
        switch isDebugModeEnabled {
        case true:
            Swift.print("\(getCurrentMillis()): \(function.rawValue): \(message)")
            
        default:
            break
        }
        
    }
    
}

/// Image upload in S3 bucket handling
extension SFManager {
    
    private func getValidFailedUseCases(_ qrInfo: CodeInfo) -> String {
        
        switch qrInfo.codeType {
        case .qr:
            switch qrInfo.distance {
            case .short:
                if let _ = qrInfo.brightNessAddedImage {
                    return FailedImageUseCases.lowLightWeChatQr.rawValue
                } else {
                    return FailedImageUseCases.weChatQr.rawValue
                }
                
            default:
                if let _ = qrInfo.brightNessAddedImage {
                    return FailedImageUseCases.lowLightLongDistanceWeChatQr.rawValue
                } else {
                    return FailedImageUseCases.longDistanceWeChatQr.rawValue
                }
            }
            
        default:
            switch qrInfo.distance {
            case .short:
                if let _ = qrInfo.brightNessAddedImage {
                    return FailedImageUseCases.lowLightZxingBar.rawValue
                } else {
                    return FailedImageUseCases.zxingBar.rawValue
                }
                
            default:
                if let _ = qrInfo.brightNessAddedImage {
                    return FailedImageUseCases.lowLightLongDistanceZxingBar.rawValue
                } else {
                    return FailedImageUseCases.longDistanceZxingBar.rawValue
                }
            }
            
        }
        
    }
    
    public func uploadFailedImagesToS3(_ failedImage: UIImage,
                                       _ qrInfo: CodeInfo) {
        
//        let parameters = ["userId": getValidUserID(),
//                          "useCase": getValidFailedUseCases(qrInfo)]
//        
//        let mediaImage = Media(withImage: failedImage, forKey: "file")
//        
//        guard let url = URL(string: Scanflow.S3.s3BucketUrl) else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = "PUT"
//        
//        let boundary = generateBoundary()
//        
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        
//        let dataBody = createDataBody(withParameters: parameters, media: [mediaImage], boundary: boundary)
//        request.httpBody = dataBody
//        
//        let session = URLSession.shared
//        session.dataTask(with: request) { (data, response, error) in
//            if let response = response {
//                SFManager.shared.print(message: "Failed image upload response: \(response)", function: .failedImageUpload)
//
//            }
//            
//            if let data = data {
//                do {
//                    let json = try JSONSerialization.jsonObject(with: data, options: [])
//                    SFManager.shared.print(message: "Failed image upload success: \(json)", function: .failedImageUpload)
//                } catch {
//                    SFManager.shared.print(message: "Failed image upload error: \(error)", function: .failedImageUpload)
//                }
//            }
//        }.resume()
        
    }
    
    private func getAnalyticId() -> String {
        if let username = UserDefaults.standard.string(forKey: "analyticId") {
            return username
        } else {
            return ""
        }

    }
    
   
    
    public func getValidUserID() -> String {
        return "\(Scanflow.S3.s3FinalPathUrl)\(getAnalyticId())/iOS"
    }
    
    private func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    public func appCenterTrack(status: String, codeType: String, isLongDistance: Bool, isLowLight: Bool) {
        var eventParams = ["USERS":"\(getAnalyticId())","OVERALL RESULT":"TOTAL \(status)","TYPE OF CODE":codeType]
        
        if (isLongDistance){
            eventParams["LONG DISTANCE"] = "TOTAL \(status)"
        }
        if (isLowLight){
            eventParams["LOW LIGHT"] = "TOTAL \(status)"
        }
       // Analytics.trackEvent("BARCODE_", withProperties: eventParams)
        
        eventParams = [:]
        eventParams["BARCODE"] = "Total Scan Performed"
        eventParams["BARCODE TYPE"] = codeType
        if (codeType == "qrcode") {
            eventParams["BARCODE 1D CODE RESULT"] = "TOTAL \(status)"
        }else{
            eventParams["BARCODE 2D CODE RESULT"] = "TOTAL \(status)"
        }
        eventParams["BARCODE RESULT"] = "TOTAL \(status)"
        if (isLongDistance){
            eventParams["LONG DISTANCE"] = "TOTAL \(status)"
        }
        if (isLowLight) {
            eventParams["LOW LIGHT"] = "TOTAL \(status)"
        }
       // Analytics.trackEvent("\(getAnalyticId())_", withProperties: eventParams)
        
        eventParams = [:]
        eventParams["\(podVersion) BARCODE"] = "TOTAL \(status)"
       // Analytics.trackEvent("VERSION_", withProperties: eventParams)
    }
    
    
    private func createDataBody(withParameters params: Parameters?, media: [Media]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename= \"\(photo.filename)\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)")
                body.append(photo.data)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
        
}
