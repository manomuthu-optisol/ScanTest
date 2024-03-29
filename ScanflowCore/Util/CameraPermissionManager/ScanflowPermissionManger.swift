//
//  CameraPermissionManager.swift
//  ScanflowCoreFramework
//
//  Created by Mac-OBS-46 on 02/09/22.
//

import Foundation
import AVFoundation
import CoreLocation

public enum CameraConfiguration {
    case success
    case failed
    case permissionDenied
}

public enum LocationConfiguration {
    case success
    case failed
    case permissionDenied
}

@objc(CameraPermissionManager)
open class ScanflowPermissionManger: NSObject {
    
    
    static public let shared = ScanflowPermissionManger()
    
     public var locationManager = CLLocationManager()

    
    private var cameraConfiguration: CameraConfiguration = .failed
    private var locationConfiguration: LocationConfiguration = .failed
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    public func attemptToLocationConfiguration() -> LocationConfiguration {
        if #available(iOS 14.0, *) {
            switch locationManager.authorizationStatus {
            case .authorized, .authorizedAlways, .authorizedWhenInUse:
                locationConfiguration = .success
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            default:
                locationConfiguration = .permissionDenied
            }
        } else {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                locationConfiguration = .permissionDenied
            case .authorizedAlways, .authorizedWhenInUse:
                locationConfiguration = .success
            default:
                locationConfiguration = .failed
            }
        }
        
        return locationConfiguration
    }
    
    public func attemptToCameraConfigureSession() -> CameraConfiguration {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraConfiguration = .success
            
        case .notDetermined:
            self.sessionQueue.suspend()
            self.requestCameraAccess(completion: { (granted) in
                self.sessionQueue.resume()
            })
            
        case .denied:
            self.cameraConfiguration = .permissionDenied
            
        default:
            break
        }
        return cameraConfiguration
    }
    
    /**
     This method requests for camera permissions.
     */
    private func requestCameraAccess(completion: @escaping (Bool) -> ()) {
        
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if !granted {
                self.cameraConfiguration = .permissionDenied
            } else {
                self.cameraConfiguration = .success
            }
            completion(granted)
        }
        
    }
    
}

