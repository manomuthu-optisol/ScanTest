//
//  CameraFeedManager+Extension.swift
//  OptiScanBarcodeReader
//
//  Created by Dineshkumar Kandasamy on 18/05/22.
//  Copyright © 2022 Optisol Business Solution. All rights reserved.

import Foundation
import UIKit
import CoreLocation

// MARK: CameraFeedManagerDelegate Declaration

@objc(ScanflowCameraManagerDelegate)
public protocol ScanflowCameraManagerDelegate: AnyObject {
    
    /**
     This method intimates that the camera permissions have been denied.
     */
    @objc(presentCameraPermissionsDeniedAlert)
    func presentCameraPermissionsDeniedAlert()
    
    /**
     This method intimates that the camera permissions have been denied.
     */
    @objc(locationAccessDeniedAlert)
    func locationAccessDeniedAlert()
    /**
     This method intimates that there was an error in video configuration.
     */
    @objc(presentVideoConfigurationErrorAlert)
    func presentVideoConfigurationErrorAlert()
    
    /**
     This method intimates that a session runtime error occurred.
     */
    @objc(sessionRunTimeErrorOccurred)
    func sessionRunTimeErrorOccurred()
    
    /**
     This method intimates that the session was interrupted.
     */
    @objc(sessionWasInterrupted:)
    func sessionWasInterrupted(canResumeManually resumeManually: Bool)
    
    /**
     This method intimates that the session interruption has ended.
     */
    @objc(sessionInterruptionEnded)
    func sessionInterruptionEnded()
   
    /**
     This method intimates that the session that will capture session..
     */
    @objc(captured:::)
    func captured(originalframe: CVPixelBuffer, overlayFrame: CGRect, croppedImage: UIImage)
    
    /**
     This method intimates that the session that will capture session..
     */
    @objc(capturedOutput:::::)
    func capturedOutput(result: String, codeType: ScannerMode, results: [String]?, processedImage:UIImage?, location: CLLocation?)
    /**
     This method intimates that the session that will capture session..
     */
    @objc(showAlert::)
    func showAlert(title: String?, message: String)
}


extension ScanflowCameraManager {
    
    /**
     This method stops a running an AVCaptureSession.
     */
    @objc
    public func stopSession() {
        self.removeObservers()
        ///UIApplication.isIdleTimerDisabled must be used from main thread only
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        ScanflowPermissionManger.shared.sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        
    }
    
    // MARK: Session Start and End methods
    
    /**
     This method starts an AVCaptureSession based on whether the camera configuration was successful.
     */
    public func checkCameraConfigurationAndStartSession() {
        ScanflowPermissionManger.shared.sessionQueue.async {
            switch self.cameraConfiguration {
            case .success:
                self.addObservers()
                self.startSession()
                
            case .failed:
                DispatchQueue.main.async {
                    self.delegate?.presentVideoConfigurationErrorAlert()
                }
                
            case .permissionDenied:
                DispatchQueue.main.async {
                    self.delegate?.presentCameraPermissionsDeniedAlert()
                }
                
            }
        }
    }
    
}

extension UIDevice {
    var hasNotch: Bool {
        if #available(iOS 11.0, *) {
            if UIApplication.shared.windows.count == 0 { return false } // Should never occur, but…
            let top = UIApplication.shared.windows[0].safeAreaInsets.top
            return top > 20 // That seem to be the minimum top when no notch…
        } else {
            // Fallback on earlier versions
            return false
        }
    }
}
