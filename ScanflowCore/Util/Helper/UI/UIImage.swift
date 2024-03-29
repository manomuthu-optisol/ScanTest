//
//  UIImage.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 28/02/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import UIKit
import VideoToolbox

extension UIImage {
    var brightness: Int {
        get {
            return self.cgImage?.brightnessValue ?? 0
        }
    }
}

extension UIImage {

    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func rotate(radians: Float) -> UIImage? {
        let size = CGSize(width: self.size.width + 200, height: self.size.height + 200)
        var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(radians * .pi / 180))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians * .pi / 180))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// Returns the data representation of the image after scaling to the given `size` and converting
    /// to grayscale.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. image size used while training the model).
    /// - Returns: The scaled image as data or `nil` if the image could not be scaled.
    public func scaledData(with size: CGSize) -> Data? {
        guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.none.rawValue)
        let _ = CGColorSpaceCreateDeviceRGB()
        
        let width = Int(size.width)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: width * 3,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: bitmapInfo.rawValue)
        else {
            return nil
        }
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        let _ = UIImage(cgImage: context.makeImage()!)
        
        guard let scaledBytes = context.makeImage()?.dataProvider?.data as Data? else { return nil }
        //    let scaledFloats = scaledBytes.map { Float32($0) / 255.0 }
        let scaledFloats = scaledBytes.map { (Float32($0) - 127.5) / 1.0 }
        
        let _ = UIImage(data: Data(copyingBufferOf: scaledFloats))
        
        return Data(copyingBufferOf: scaledFloats)
    }

     func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 414, height: 896)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
}



extension UIImage {
    public convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}



extension UIImage {
    
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        if let pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pixelData, width: Int(self.size.width),
                                    height: Int(self.size.height), bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                    space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)

            UIGraphicsPushContext(context!)
            self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
            UIGraphicsPopContext()
            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

            return pixelBuffer
        }

        return nil
    }
}

extension UIImage {
    
    public func toPixelBuffer() -> CVPixelBuffer {
        let cgimage = self.cgImage
        let frameSize = CGSize(width: self.size.width, height: self.size.height)
        var pixelBuffer:CVPixelBuffer? = nil
        let _ = CVPixelBufferCreate(kCFAllocatorDefault, Int(cgimage?.width ?? 0), Int(cgimage?.height ?? 0), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: data, width: Int(frameSize.width),
                                height: Int(frameSize.height), bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        
        context?.draw(cgimage!, in: CGRect(x: 0, y: 0, width: cgimage?.width ?? 0, height: cgimage?.height ?? 0))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer!
        
    }
    

}

//public func convertToCMSampleBuffer(_ cvPixelBuffer: CVPixelBuffer) -> CMSampleBuffer {
//    let pixelBuffer = cvPixelBuffer
//    var newSampleBuffer: CMSampleBuffer? = nil
//    var timimgInfo: CMSampleTimingInfo = .invalid
//    var videoInfo: CMVideoFormatDescription? = nil
//    CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
//    CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
//                                       imageBuffer: pixelBuffer,
//                                       dataReady: true,
//                                       makeDataReadyCallback: nil,
//                                       refcon: nil,
//                                       formatDescription: &videoInfo,
//                                       sampleTiming: &timimgInfo,
//                                       sampleBufferOut: &newSampleBuffer)
//   // CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer!, true, nil, nil, videoInfo!, &timimgInfo, &newSampleBuffer)
//    return newSampleBuffer!
//}

public func convertCMSampleBuffer(_ cvPixelBuffer: CVPixelBuffer?) -> CMSampleBuffer {
    
    var pixelBuffer = cvPixelBuffer
    CVPixelBufferCreate(kCFAllocatorDefault, 100, 100, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

    var info = CMSampleTimingInfo()
    info.presentationTimeStamp = CMTime.zero
    info.duration = CMTime.invalid
    info.decodeTimeStamp = CMTime.invalid

    var formatDesc: CMFormatDescription?
    CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer!,
                                                 formatDescriptionOut: &formatDesc)

    var sampleBuffer: CMSampleBuffer?

    CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                             imageBuffer: pixelBuffer!,
                                             formatDescription: formatDesc!,
                                             sampleTiming: &info,
                                             sampleBufferOut: &sampleBuffer)

    return sampleBuffer!
}
