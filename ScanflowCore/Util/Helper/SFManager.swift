//
//  SFManager.swift
//  ScanFlowApp
//
//  Created by Dineshkumar Kandasamy on 06/06/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.
//

import Foundation
import Vision
import opencv2
import UIKit
//import AppCenter
//import AppCenterAnalytics
//import AppCenterCrashes

/// Scan Flow Manager
public class SFManager {
    
    static public let shared = SFManager()
    
    let sequenceHandler = VNSequenceRequestHandler()

    public var settings: SFSettings! = SFSettings()

    public var isDebugModeEnabled: Bool! = false
    
   public var results: SFResultHandler! = SFResultHandler()
    
    public var config: SFConfig! = SFConfig()
    
    public var resultArray: [SFResultHandler] = []
    
    public var currentFrameBrightness: Double?

    public let podVersion = "1.2.2"
    init() {
        
    }
    
    ///Initial Config and Zoom settings
    public func initalZoomSettings(_ zoomSettings: ZoomOptions) {
        
        self.settings.zoomMode = zoomSettings
        self.config.lastZoomFactor = 1.2
        
        self.settings.zoomSettings.currentZoomLevel = 1.2
        self.settings.zoomSettings.detectionWithDecodeFailedCount = 0
        self.settings.zoomSettings.detectionState = .none
        
    }
    
    ///Enble Debug Mode
   
    public func enbleDebugMode(enable: Bool) {
        self.isDebugModeEnabled = enable
    }
    
    
    ///Initial Auto Zoom settings
   
    public func initialAutoZoomSetup() {
        
        self.settings.isDetectionFound = false
        self.settings.isAutoZoomEnabled = true
        self.settings.noDetectionCount = 5
        self.settings.isTouchToZoomEnabled = false
    }
    
    ///Initial Auto Zoom settings
    public func initialTouchToZoomSetup() {
        
        self.settings.isAutoZoomEnabled = false
        self.settings.isTouchToZoomEnabled = false
        self.settings.isDetectionFound = false
        self.settings.noDetectionCount = 5
        
    }
    
    private func saveValidImages(_ image: UIImage?) {
        if let validImage = image {
            UIImageWriteToSavedPhotosAlbum(validImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc
    private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            SFManager.shared.print(message: error.localizedDescription, function: .longDistance)
        } else {
            SFManager.shared.print(message: "Your image has been saved to your photos. \(contextInfo.debugDescription)", function: .imageSaved)
        }
    }
    
    
    /// Reset Touch To Zoom
    func resetTouchToZoom() {
        self.settings.isTouchToZoomEnabled = false
        self.settings.isDetectionFound = false
    }
    
    public func getCurrentMillis() -> String {
        
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss.SSSS"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        return dateString
        
    }
    
    /// Manage Beep Sound
    /// - Returns: Sound file name
    private func manageBeepSound(forCode: PlayBeepFor) -> URL? {
        let bundle = Bundle(for: type(of: self))
        guard let litePath = bundle.url(forResource: forCode == .normal ? "beep" : "oneofmany_beep", withExtension: "wav") else {
            return nil
        }
        return litePath
    }
    
func getBundlePath(fileName: String, fileExtension: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        return bundle.path(forResource: fileName, ofType: fileExtension)
    }
    
    public func playBeep(forCode: PlayBeepFor) {
        if let soundPath = manageBeepSound(forCode: forCode) {
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundPath as CFURL, &soundID)
            AudioServicesPlaySystemSound(soundID)
        } else {
            AudioServicesPlaySystemSound(SystemSoundID(1106))
        }
    }
    
    public func saveAnalytic(id: String) {
        UserDefaults.standard.set(id, forKey: "analyticId")
        UserDefaults.standard.synchronize()
        configureAnalytic(analyticId: id)
    }
    
    public func configureAnalytic(analyticId: String) {
//            AppCenter.start(withAppSecret: analyticId, services:[
//              Analytics.self,
//              Crashes.self
//            ])
//            Analytics.enabled = true
//            Analytics.startSession()
    }
    
    
    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat, apperance: OverlayViewApperance) -> UIImage?

        {

            let imageViewWidthScale = (inputImage.size.width / viewWidth)
            let imageViewHeightScale = inputImage.size.height / viewHeight



            // Scale cropRect to handle images larger than shown-on-screen size

            let cropZone = CGRect(x:cropRect.origin.x * (imageViewWidthScale),

                                  y:cropRect.origin.y * imageViewHeightScale,

                                  width:cropRect.size.width * (imageViewWidthScale),

                                  height:cropRect.size.height * imageViewHeightScale)



            // Perform cropping in Core Graphics

            if let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone) {

                // Return image to UIImage

                let croppedImage: UIImage = UIImage(cgImage: cutImageRef)

                return croppedImage

            } else {

                guard let ciImage = inputImage.ciImage else {return nil}

                let context = CIContext(options: nil)

                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {return nil}

                let croppedImage: UIImage = UIImage(cgImage: cgImage)

                return croppedImage

            }

       }
    
}

typealias Parameters =  [String: String]


extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
