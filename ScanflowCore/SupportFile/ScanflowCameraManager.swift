//
//  ScanflowCameraManager.swift
//  ScanflowCoreFramework
//
//  Created by Mac-OBS-46 on 02/09/22.
//

import Foundation
import AVFoundation
import CoreImage
import AudioToolbox
import Vision
import UIKit
import Security
import Accelerate
import CoreLocation
import CommonCrypto
import opencv2

@objc(CaptureDelegate)
public protocol CaptureDelegate: AnyObject {
    @objc(readData::)
    func readData(originalframe: CVPixelBuffer, croppedFrame: CVPixelBuffer)
}

@objc(UpdateSeclectedResultDelegate)
public protocol UpdateSeclectedResultDelegate: AnyObject {
    @objc(updateTouchBasedResult)
     func updateTouchBasedResult()
}

@objc(ScanflowCameraManager)
open class ScanflowCameraManager: ScanflowPermissionManger, AVCaptureMetadataOutputObjectsDelegate {
    
    @objc public weak var captureDelegate: CaptureDelegate?
    @objc public weak var selectedDelegate: UpdateSeclectedResultDelegate?
    public var pinchGesture: UIPinchGestureRecognizer!
    public var captureDevice: AVCaptureDeviceInput?
    private lazy var videoDataOutput = AVCaptureVideoDataOutput()
    public weak var settingsButton: UIButton!
    public weak var touchToZoomButton: UIButton!
    public var outterWhiteRectView: UIView!
    public weak var blinkLabel: UILabel!
    public weak var expireLabel: UILabel!
    private weak var waterMarkLabel: UILabel!
    public var touchedPosition: CGPoint?
    public var scanningDetails: CodeInfo = CodeInfo()
    public var previewView: PreviewView

    private var islicenceExpired: Bool = false
    public var overlayView: OverlayView!
    public var scannerType: ScannerMode = .qrcode
    
    var session: AVCaptureSession = AVCaptureSession()
    public var previewSize: CGSize?
    var isSessionRunning = false
    private var overlayApperance: OverlayViewApperance = .square
    var cameraConfiguration: CameraConfiguration = .failed
    public var toBeSendInDelegate = true
    public var isFrameProcessing: Bool = false
    public var currentCoordinates: CLLocation?
    public var captureStarted: Bool = true

    //Arc color
    private var leftTopArc: UIColor?
    private var leftDownArc: UIColor?
    private var rightTopArc: UIColor?
    private var rightDownArc: UIColor?
    
    let leftTopImage: UIImageView = UIImageView()
    let rightTopImage: UIImageView = UIImageView()
    let leftBottomImage: UIImageView = UIImageView()
    let rightBottomImage: UIImageView = UIImageView()
    
    private var maskContainer: CGRect {
        var maskSize = CGSize.zero
        switch overlayApperance {
        case .square:
            maskSize = CGSize(width: (previewSize!.width * 0.7), height: (previewSize!.width * 0.7))
        case .rectangle:
            maskSize = CGSize(width: (previewSize!.width * 0.85), height: (previewSize!.width * 0.12))
        case .hide:
            maskSize = CGSize.zero
        case .tire:
            maskSize = CGSize(width: (previewSize!.width * 0.85), height: (previewSize!.width * 0.22))
        case .containerHorizantal:
            maskSize = CGSize(width: (previewSize!.width * 0.8), height: (previewSize!.height * 0.13))
        case .containerVerticle:
            maskSize = CGSize(width: (previewSize!.width * 0.25), height: (previewSize!.height * 0.45))
        default:
            maskSize = CGSize.zero
        }
        return CGRect(x: (((self.previewView.bounds.size.width - maskSize.width) - 24) / 2),
                      y: (((self.previewView.bounds.size.height - maskSize.height) - 0) / 2),
                      width: maskSize.width, height: maskSize.height)
    }
    private var imageTobeCrop: Bool = false
    private var isLowLightEnchancementNeed: Bool = true
    @objc public weak var delegate: ScanflowCameraManagerDelegate?
    public let shapeLayer = CAShapeLayer()
    public var previewViewSize: CGSize {
        get { return previewView.frame.size }
    }
    
    let path = UIBezierPath()
    public let documentShapeLayer = CAShapeLayer()
    /**
     Initializes a Camera manager function which configures all camera related function and Camera configurations..
     
     - Parameters:
     - previewView: A view which is used to show camera frames.
     - installedDate: We have to get app installed date
     - scannerType: Scanner type is like 'qrcode' 'barcode' and etc
     - overCropNeed: Which means it will get outimage as cropped image with respect to overlay frame
     - overlayApperance: This represents overlay apperance like 'rectangle' 'square' are 'hide'
     
     */
    public init(previewView: UIView, scannerMode: ScannerMode, overlayApperance: OverlayViewApperance, overCropNeed: Bool = false, leftTopArc: UIColor = .topLeftArrowColor, leftDownArc: UIColor = .bottomLeftArrowColor, rightTopArc: UIColor = .topRightArrowColor, rightDownArc: UIColor = .bottomRightArrowColor, locationNeed: Bool = false) {

        self.overlayApperance = overlayApperance
        self.imageTobeCrop = overCropNeed
        self.leftTopArc = leftTopArc
        self.leftDownArc = leftDownArc
        self.rightTopArc = rightTopArc
        self.rightDownArc = rightDownArc

        self.scannerType = scannerMode
        self.previewView = PreviewView(frame: previewView.bounds)
        previewView.addSubview(self.previewView)
        super.init()
        locationManager.delegate = self
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            return
        }
        
        overlayView = OverlayView()
        // Initializes the session
        session.sessionPreset = .hd1920x1080
        self.previewView.session = session
        SFManager.shared.results.successfulDetectionCount = 0
        
        
        self.previewView.previewLayer.connection?.videoOrientation = .portrait
        self.previewView.previewLayer.videoGravity = .resizeAspectFill
        
        self.previewSize = self.previewView.bounds.size
        
        overlayView.frame = self.previewView.bounds
        overlayView.backgroundColor = UIColor.clear
        overlayView.clipsToBounds = true
        let outterWhiteRectViewItem = createOverlay(apperance: overlayApperance)
        
        self.outterWhiteRectView = outterWhiteRectViewItem
        let screenBounds = previewView.bounds
        self.outterWhiteRectView.frame = CGRect(
            x: ((screenBounds.width / 2) - (outterWhiteRectView.frame.width / 2)),
            y: ((screenBounds.height / 2) - (outterWhiteRectView.frame.height / 2) - 10),
            width: self.outterWhiteRectView.frame.width,
            height: self.outterWhiteRectView.frame.height)
        
        self.previewView.addSubview(self.outterWhiteRectView)
        self.previewView.bringSubviewToFront(self.outterWhiteRectView)
        
        SFManager.shared.print(message: "Start Camera Config", function: .superResolutionStart)
        
        
        if ScanflowPermissionManger.shared.attemptToCameraConfigureSession() == .success {
            newConfigureSession()
        } else {
            self.delegate?.presentCameraPermissionsDeniedAlert()
        }
        
        if locationNeed {
            if ScanflowPermissionManger.shared.attemptToLocationConfiguration() == .success {
                locationManager.startUpdatingLocation()
            } else {
                self.delegate?.locationAccessDeniedAlert()
            }
        }
        
        scanFlowConfigSetup()
        self.previewView.layer.addSublayer(documentShapeLayer)
        if overlayApperance == .hide {
            self.leftTopImage.isHidden = true
            self.leftBottomImage.isHidden = true
            self.rightTopImage.isHidden = true
            self.rightBottomImage.isHidden = true

        }
       // updateWaterMarkLabel()
        
        if scannerType == .tire || scannerType == .containerHorizontal || scannerType == .containerVertical || scannerType == .dotTire {
            let overlayPath = UIBezierPath(rect: self.previewView.bounds)
            let transparentPath = UIBezierPath(roundedRect: outterWhiteRectViewItem.frame, byRoundingCorners: [.allCorners], cornerRadii: CGSizeMake(16.0, 16.0))
            overlayPath.append(transparentPath)
            overlayPath.usesEvenOddFillRule = true
            
            let fillLayer = CAShapeLayer()
            fillLayer.path = overlayPath.cgPath
            fillLayer.fillRule = .evenOdd
            fillLayer.fillColor = UIColor.black.withAlphaComponent(0.2).cgColor
            self.previewView.layer.addSublayer(fillLayer)
        }
    }
    
    deinit {
        
    }
    
    public func updateScanner(mode: ScannerMode) {

        if mode == .containerVertical {
            self.previewView.layer.sublayers?.last?.removeFromSuperlayer()
            self.overlayApperance = .containerVerticle
            self.scannerType = .containerVertical
        } else if mode == .containerHorizontal {
            self.previewView.layer.sublayers?.last?.removeFromSuperlayer()

            self.overlayApperance = .containerHorizantal
            self.scannerType = .containerHorizontal
        }
        let outterWhiteRectViewItem = createOverlay(apperance: overlayApperance)
        self.outterWhiteRectView = outterWhiteRectViewItem
        let screenBounds = previewView.bounds
        self.outterWhiteRectView.frame = CGRect(
            x: ((screenBounds.width / 2) - (outterWhiteRectView.frame.width / 2)),
            y: ((screenBounds.height / 2) - (outterWhiteRectView.frame.height / 2) - 10),
            width: self.outterWhiteRectView.frame.width,
            height: self.outterWhiteRectView.frame.height)
        
       self.previewView.addSubview(self.outterWhiteRectView)
        self.previewView.bringSubviewToFront(self.outterWhiteRectView)
        
        SFManager.shared.print(message: "Start Camera Config", function: .superResolutionStart)
        
        if scannerType == .tire || scannerType == .containerHorizontal || scannerType == .containerVertical || scannerType == .dotTire {
            let overlayPath = UIBezierPath(rect: self.previewView.bounds)
            let transparentPath = UIBezierPath(roundedRect: outterWhiteRectViewItem.frame, byRoundingCorners: [.allCorners], cornerRadii: CGSizeMake(16.0, 16.0))
            overlayPath.append(transparentPath)
            overlayPath.usesEvenOddFillRule = true
            
            let fillLayer = CAShapeLayer()
            fillLayer.path = overlayPath.cgPath
            fillLayer.fillRule = .evenOdd
            fillLayer.fillColor = UIColor.black.withAlphaComponent(0.2).cgColor
            self.previewView.layer.addSublayer(fillLayer)
        }
        
    }
    
    /**
     This function for creating Overlay
     
     - Parameters:
     - apperance: This property is consider as a shape of overlay apperance like 'square' 'rectangular' or 'hide'
     
     */
    private func createOverlay(apperance: OverlayViewApperance) -> UIView {
        let overlayView = UIView(frame: self.previewView.bounds)
        overlayView.backgroundColor = UIColor.clear
        
        
        // MARK: - Edged Corners
        
        overlayView.frame = CGRect(x: maskContainer.minX, y: maskContainer.minY, width: (maskContainer.maxX - maskContainer.minX), height: (maskContainer.maxY - maskContainer.minY))
       
        let arcSize = overlayApperance == .containerVerticle || overlayApperance == .containerHorizantal ? 25 : 32
        if let imagePath = SFManager.shared.getBundlePath(fileName: "leftTop", fileExtension: "png") {
            leftTopImage.image = (UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysTemplate))!
            if let imgColor = leftTopArc {
                leftTopImage.tintColor = imgColor
            }
            leftTopImage.frame = CGRect(x: 0, y: 0, width:  arcSize, height: arcSize)
            overlayView.addSubview(leftTopImage)
        }
        
        if let imagePath = SFManager.shared.getBundlePath(fileName: "rightTop", fileExtension: "png") {
            rightTopImage.image = (UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysTemplate))!
            if let arcColor = rightTopArc {
                rightTopImage.tintColor = arcColor
            }
            rightTopImage.frame = CGRect(x: (overlayView.frame.width - 32), y: 0, width: 32, height: 32)
            overlayView.addSubview(rightTopImage)
        }
        
        if let imagePath = SFManager.shared.getBundlePath(fileName: "leftBottom", fileExtension: "png") {
            leftBottomImage.image = (UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysTemplate))!
            if let arcImage = leftDownArc {
                leftBottomImage.tintColor = arcImage
            }
            leftBottomImage.frame = CGRect(x: 0, y: (overlayView.frame.height - 32), width: 32, height: 32)
            overlayView.addSubview(leftBottomImage)
        }
        
        if let imagePath = SFManager.shared.getBundlePath(fileName: "rightBottom", fileExtension: "png")  {
            rightBottomImage.image = (UIImage(contentsOfFile: imagePath)?.withRenderingMode(.alwaysTemplate))!
            if let arcImageColor = rightDownArc {
                rightBottomImage.tintColor = arcImageColor
            }
            rightBottomImage.frame = CGRect(x: (overlayView.frame.width - 32), y: (overlayView.frame.height - 32), width: 32, height: 32)
            overlayView.addSubview(rightBottomImage)
        }
        
        if scannerType == .oneOfMany || scannerType == .batchInventory || scannerType == .docuementScaning {
            overlayView.isHidden = true
        } else {
            overlayView.isHidden = false
        }
        
        
        return overlayView
    }

    internal func addObservers() {
        
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(ScanflowCameraManager.sessionRuntimeErrorOccurred(notification:)),
                                               name: NSNotification.Name.AVCaptureSessionRuntimeError,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ScanflowCameraManager.sessionWasInterrupted(notification:)),
                                               name: NSNotification.Name.AVCaptureSessionWasInterrupted,
                                               object: session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ScanflowCameraManager.sessionInterruptionEnded),
                                               name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
                                               object: session)
    }
    
    internal func removeObservers() {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
        
    }
    
    // MARK: Notification Observers
    
    @objc
    private func sessionWasInterrupted(notification: Notification) {
        
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            SFManager.shared.print(message: "Capture session was interrupted with reason \(reason)", function: .longDistance)
            
            var canResumeManually = false
            if reason == .videoDeviceInUseByAnotherClient {
                canResumeManually = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                canResumeManually = false
            }
            
            self.delegate?.sessionWasInterrupted(canResumeManually: canResumeManually)
            
        }
    }
    
    public func drawPath(boundRect:[CGPoint]) {
        path.removeAllPoints()
        if boundRect.count != 0 {
            path.move(to: boundRect[0])
            
            //
            // Draw lines to the remaining points
            path.addLine(to: boundRect[1])
            path.addLine(to: boundRect[2])
            path.addLine(to: boundRect[3])
            path.close()
            
        }
        documentShapeLayer.path = path.cgPath
        documentShapeLayer.strokeColor = UIColor.optiScanBoundingBoxColor.cgColor
        documentShapeLayer.fillColor = UIColor.optiScanBoundingBoxColor.withAlphaComponent(0.3).cgColor
        documentShapeLayer.masksToBounds = false
        documentShapeLayer.shadowColor = UIColor.black.cgColor
        documentShapeLayer.shadowOpacity = 0.2
        documentShapeLayer.shadowOffset = .zero
        documentShapeLayer.shadowRadius = 3
        documentShapeLayer.lineWidth = boundRect.count == 0 ? 0.0 : 2.0
    }
    
    @objc
    private func sessionInterruptionEnded(notification: Notification) {
        self.delegate?.sessionInterruptionEnded()
    }
    
    /**
     This function for showing and hiding overlay
     
     - Parameters:
     - isHidden: if its true means overlay will hide, if its false means overlay will be shown
     
     */
    @objc(updateOverlay:)
    public func updateOverlay(isHidden: Bool) {
        shapeLayer.strokeColor = isHidden == true ? UIColor.clear.cgColor : SFManager.shared.config.lineColor.cgColor
    }
    
    @objc
    func sessionRuntimeErrorOccurred(notification: Notification) {
        
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        
        SFManager.shared.print(message: "Capture session runtime error: \(error)", function: .longDistance)
        
        if error.code == .mediaServicesWereReset {
            ScanflowPermissionManger.shared.sessionQueue.async {
                if self.isSessionRunning {
                    self.startSession()
                } else {
                    DispatchQueue.main.async {
                        self.delegate?.sessionRunTimeErrorOccurred()
                    }
                }
            }
        } else {
            self.delegate?.sessionRunTimeErrorOccurred()
            
        }
    }

    /**
     This method starts the AVCaptureSession, Once its call session captures all frames and then process the captured frames
     */
    @objc(startSession)
    public func startSession() {
        ///UIApplication.isIdleTimerDisabled must be used from main thread only
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
            
        }
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    /**
     This is the process of validating license from user
     
     - Parameters:
     - authKey: Have to enter Auth key which we got from from our official site : scanflow.ai
     */
    @objc(validateLicense::)
    public func validateLicense(authKey : String, productType: CaptureType) {
        var product = ""
        switch productType {

            case .barcodeCapture:
                product = "Barcode_Capture"

            case .textCapture:
                product = "Barcode_Capture"

            case .idCapture:
                product = "Id_Capture"

            case .documentCapture:
                product = "Document_Capture"
        }
        ScanflowLicenseManager.shared.previewView = previewView
        ScanflowLicenseManager.shared.outerWhiteRectView = outterWhiteRectView
        ScanflowLicenseManager.shared.validateLicense(key: authKey, productType: product)
    }
    
    public func updateWaterMarkLabel() {
        
        let expireLabelItem = UILabel()
        expireLabelItem.translatesAutoresizingMaskIntoConstraints = false
        expireLabelItem.numberOfLines = 0
        expireLabelItem.alpha = 0
        expireLabelItem.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        expireLabelItem.textAlignment = .center
        expireLabelItem.text = Scanflow.Texts.expireAlert
        self.expireLabel = expireLabelItem
        self.previewView.addSubview(expireLabelItem)

        var waterMarkLabelItem: UILabel?
        if scannerType != .docuementScaning {
            waterMarkLabelItem = UILabel(frame: CGRect(x: ((maskContainer.origin.x + maskContainer.width) - 100),
                                                       y: (maskContainer.origin.y + maskContainer.height), width: 100, height: 30))

            
        } else {
            waterMarkLabelItem = UILabel(frame: CGRect(x: (self.previewView.frame.width - 120), y: (self.previewView.frame.height - 35), width: 100, height: 30))
        }
        if overlayApperance == .hide {
            waterMarkLabelItem = UILabel(frame: CGRect(x: (self.previewView.frame.width - 120), y: (self.previewView.frame.height - 35), width: 100, height: 30))
        }
        waterMarkLabelItem?.textColor = .white.withAlphaComponent(0.5)
        waterMarkLabelItem?.textAlignment = .right
        waterMarkLabelItem?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        waterMarkLabelItem?.text = Scanflow.Texts.waterMark

        if scannerType == .docuementScaning {
            self.previewView.addSubview(waterMarkLabelItem!)
            self.previewView.bringSubviewToFront(waterMarkLabelItem!)
        } else {
            self.waterMarkLabel = waterMarkLabelItem!
            self.overlayView.addSubview(waterMarkLabelItem!)
        }
        if overlayApperance != .hide {
            NSLayoutConstraint.activate([
                
                expireLabel.centerXAnchor.constraint(equalTo: previewView.centerXAnchor),
                expireLabel.centerYAnchor.constraint(equalTo: previewView.centerYAnchor),
                expireLabel.leftAnchor.constraint(equalTo: previewView.leftAnchor, constant: 30),
                expireLabel.rightAnchor.constraint(equalTo: previewView.rightAnchor, constant: -30),
                
            ])
        } else {
            NSLayoutConstraint.activate([
                
                expireLabel.bottomAnchor.constraint(equalTo: previewView.bottomAnchor, constant: -30),
                expireLabel.leftAnchor.constraint(equalTo: previewView.leftAnchor, constant: 30),
                expireLabel.rightAnchor.constraint(equalTo: previewView.rightAnchor, constant: -30),
                
            ])
        }
        
    }
    
    private func scanFlowConfigSetup() {
        updateScanFlowSettings(.normal)
        self.setupPinchGesture()
    }
    
    
    /**
     This is the process of validating license from user
     
     - Parameters:
     - zoomSettings: Have configure zoom level here
     
     */
    
    public func updateScanFlowSettings(_ zoomSettings: ZoomOptions) {
        
        SFManager.shared.initalZoomSettings(zoomSettings)
        
        switch SFManager.shared.settings.zoomMode {
        case .autoZoom:
            SFManager.shared.initialAutoZoomSetup()
            
        default:
            SFManager.shared.initialTouchToZoomSetup()
            
        }
        
        /// Set initial zoom factor to match
        guard let device = captureDevice?.device else { return }
        let newScaleFactor = minMaxZoom(SFManager.shared.config.defaultInitialZoomFactor * SFManager.shared.config.lastZoomFactor, device: device)
        SFManager.shared.config.lastZoomFactor = minMaxZoom(newScaleFactor, device: device)
        updateInitialZoomFactor(scale: SFManager.shared.config.lastZoomFactor, device: device)
        
        
    }
    
    private func setupPinchGesture() {
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action:#selector(pinch(_:)))
        let tap = UITapGestureRecognizer(target: self, action: #selector(touchedScreen(position:)))
        self.pinchGesture = pinchRecognizer
        self.previewView.addGestureRecognizer(pinchRecognizer)
        self.previewView.addGestureRecognizer(tap)
        overlayView.frame = previewView.bounds
        overlayView.backgroundColor = UIColor.clear
        previewSize = previewView.frame.size
        previewView.addSubview(overlayView)
        
        /// Set initial zoom factor to match
        guard let device = captureDevice?.device else { return }
        let newScaleFactor = minMaxZoom(SFManager.shared.config.defaultInitialZoomFactor * SFManager.shared.config.lastZoomFactor, device: device)
        SFManager.shared.config.lastZoomFactor = minMaxZoom(newScaleFactor, device: device)
        updateInitialZoomFactor(scale: SFManager.shared.config.lastZoomFactor, device: device)
        
    }
    
    /**
     This is the process of resolution of capturing the frame
     
     - Parameters:
     - previewView: This view we are using capture the preview view
     - installedDate: Date of installation
     - resolutionDetail: by deafult it set as 1280X720,  if you send as 1 it set as medium, if 2 means 1280x720, if 3 means 1920x1080, if 4 means 4K.
     
     */
    @objc(setResolution:)
    public func setResolution(resolutionDetail: ResolutionTypes) {
        
        
        overlayView = OverlayView()
        
        // resolution
        switch resolutionDetail {
            case .medium:
            session.sessionPreset =  .medium
            case .hd1280x720:
            session.sessionPreset =  .hd1280x720
            case .hd1920x1080:
            session.sessionPreset =  .hd1920x1080
            case .hd4K3840x2160:
            session.sessionPreset =  .hd4K3840x2160
            
        default:
            session.sessionPreset =  .hd1280x720
        }
        
        self.previewView.session = session

        
        SFManager.shared.print(message: "Start Camera Config", function: .superResolutionStart)
        
        
        SFManager.shared.print(message: "End Camera Config", function: .superResolutionStart)

        scanFlowConfigSetup()
    }
    
    /**
     This function used for getting current zoom level.
     
     - Parameters:
     - _: setting zoom factor
     - device: We have to send 'session'  to this funtion for min max
     
     
     */
    public func minMaxZoom(_ factor: CGFloat, device: AVCaptureDevice) -> CGFloat {
        return min(min(max(factor, SFManager.shared.config.minimumZoom), SFManager.shared.config.maximumZoom), device.activeFormat.videoMaxZoomFactor)
    }
    
    @objc private func touchedScreen(position: UITapGestureRecognizer) {
        touchedPosition = position.location(in: self.previewView)
        selectedDelegate?.updateTouchBasedResult()
    }

    @objc
    private func pinch(_ pinch: UIPinchGestureRecognizer) {
        
        guard let device = captureDevice?.device else { return }
        
        let newScaleFactor = minMaxZoom(pinch.scale * SFManager.shared.config.lastZoomFactor, device: device)
        
        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor, device: device)
        case .ended:
            SFManager.shared.config.lastZoomFactor = minMaxZoom(newScaleFactor,device: device)
            update(scale: SFManager.shared.config.lastZoomFactor,device: device)
        default: break
        }
        
    }
    
    /**
     This function used for increasing zoom level, Once its reach maximum zoom level it retuns to default zoom level.
     
     */
    @objc(touchToZoomButtonAction)
    public func touchToZoomButtonAction() {
        
        if SFManager.shared.settings.isTouchToZoomEnabled == false {
            
            SFManager.shared.settings.isTouchToZoomEnabled = true
            self.enableZoom(.touchToZoom)
            
        } else if SFManager.shared.settings.isTouchToZoomEnabled == true && SFManager.shared.settings.isDetectionFound == true {
            
            SFManager.shared.settings.isTouchToZoomEnabled = false
            SFManager.shared.settings.isDetectionFound = false
            self.resetZoomFactor(.touchToZoom)
            
        } else {
            SFManager.shared.print(message: "No Action", function: .superResolutionStart)
        }
        
    }
    
    @objc(flashLight:)
    public func flashLight(enable: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            
            try device.setTorchModeOn(level: 1.0)
            device.torchMode = enable == true ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling Flashlight: \(error)")
        }
    }
    
    /**
     This function used for updating zoom level
     
     - Parameters:
     - _:  setting zoom level
     
     */
    @objc(enableZoom:)
    public func enableZoom(_ zoomMode: ZoomOptions) {
        
        
        switch SFManager.shared.settings.zoomSettings.detectionState {
        case .none:
            zoomNearToCode(zoomMode)
            SFManager.shared.print(message: "ZOOM: Continue scan", function: .processResults)
            
        case .failed:
            if SFManager.shared.config.lastZoomFactor <= 10 && SFManager.shared.config.lastZoomFactor >= 8 {
                SFManager.shared.print(message: "ZOOM: Increased maximum zoom level", function: .processResults)
                zoomNearToCode(zoomMode)
                return
            } else {
                zoomNearToCode(zoomMode)
                SFManager.shared.print(message: "ZOOM: Increase one zoom level", function: .processResults)
            }
            
        default:
            SFManager.shared.print(message: "ZOOM: Stop scan", function: .processResults)
            return
            
        }
        
    }
    
    /**
     Once maximun zoom level maximum level reached we have to reset zoom level.
     
     - Parameters:
     - zoomMode: we have set zoomOption , normal , autoZoom, nearToZoom.
     
     */
    public func resetZoomFactor(_ zoomMode: ZoomOptions) {
        
        guard let device = captureDevice?.device else { return }
        
        SFManager.shared.config.lastZoomFactor = 1.2
        
        let newScaleFactor = self.minMaxZoom(SFManager.shared.config.defaultInitialZoomFactor * SFManager.shared.config.lastZoomFactor,
                                             device: device)
        SFManager.shared.config.lastZoomFactor = self.minMaxZoom(newScaleFactor, device: device)
        
        self.update(scale: SFManager.shared.config.lastZoomFactor, device: device)
        
        switch zoomMode {
        case .autoZoom:
            break
            
        default:
            SFManager.shared.resetTouchToZoom()
        }
        
        
    }
    
    public func zoomNearToCode(_ zoomMode: ZoomOptions) {
        
        guard let device = captureDevice?.device else { return }
        
        SFManager.shared.print(message: "Current zoom level \(SFManager.shared.config.lastZoomFactor)", function: .processResults)
        
        //Here we check lastZoomFactor as 8, it denotes that after zoom percentage 8 it will reset zoom. As per test case document we made as 8(80%).
        if SFManager.shared.config.lastZoomFactor >= 8 {
            
            SFManager.shared.config.resetCount += 1
            
            if SFManager.shared.config.resetCount > 4 {
                SFManager.shared.print(message: "ZOOM FACTOR BEFORE RESET: \(SFManager.shared.config.lastZoomFactor)", function: .processResults)
                SFManager.shared.config.resetCount = 0
                self.resetZoomFactor(zoomMode)
            }
            
            SFManager.shared.print(message: "ZOOM TIMER ENABLED", function: .processResults)
            
        } else {
            
            SFManager.shared.print(message: "ZOOM CONTINUES", function: .processResults)
            
            let newScaleFactor = minMaxZoom(SFManager.shared.config.defaultInitialZoomFactor * SFManager.shared.config.lastZoomFactor, device: device)
            SFManager.shared.config.lastZoomFactor = minMaxZoom(newScaleFactor, device: device)
            update(scale: SFManager.shared.config.lastZoomFactor, device: device)
            
        }
        
    }
    
    public func update(scale factor: CGFloat, device: AVCaptureDevice) {
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.ramp(toVideoZoomFactor: factor, withRate: 3)
            
        } catch {
            SFManager.shared.print(message: "\(error.localizedDescription)", function: .updateCameraScale)
        }
    }
    
    public func updateInitialZoomFactor(scale factor: CGFloat, device: AVCaptureDevice) {
        
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            device.videoZoomFactor = factor
            
        } catch {
            SFManager.shared.print(message: "\(error.localizedDescription)", function: .updateCameraScale)
        }
    }
    
    private func newConfigureSession() {
        
        let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [ String(kCVPixelBufferPixelFormatTypeKey) : kCMPixelFormat_32BGRA]
        /**Tries to get the default back camera.
         */
        if let camera  = AVCaptureDevice.default(for: .video) {
            //camera.isFocusModeSupported(.continuousAutoFocus)
            do {
                
                let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
                
                self.captureDevice = videoDeviceInput

                
            } catch {
                print("Cannot create video device input")
            }
            
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
                videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
            }
            
            self.startSession()
            SFManager.shared.print(message: "Session Started", function: .superResolutionStart)
            
        }
        
    }
    
    
    public func lowLightHandler(_ imagePixelBuffer: CVPixelBuffer, _ pixelBuffer: CMSampleBuffer) {
        let brightnessLevel = SFManager.shared.getBrightnessValue(pixelBuffer)
        if (brightnessLevel < -2) {
            processImageForDelegate(pixelBuffer: imagePixelBuffer, brightnessValue: brightnessLevel)
        } else if brightnessLevel < 0.5 {
            var bufferResult: CVPixelBuffer?
            if imageTobeCrop == true {
                bufferResult = imagePixelBuffer
            } else {
                bufferResult = imagePixelBuffer
                
            }
            processImageForDelegate(pixelBuffer: bufferResult!, brightnessValue: brightnessLevel)
            
        } else {
            processImageForDelegate(pixelBuffer: imagePixelBuffer, brightnessValue: brightnessLevel)
            
        }
        
    }
    
    private func processImageForDelegate(pixelBuffer: CVPixelBuffer, brightnessValue: Double) {
        let convertedImage = pixelBuffer.toImage()
        if imageTobeCrop == true {
            DispatchQueue.main.async {
                SFManager.shared.currentFrameBrightness = brightnessValue
                let croppedImage = SFManager.shared.cropImage(convertedImage,
                                                              toRect: self.outterWhiteRectView.frame,
                                                              viewWidth: self.previewView.frame.width,
                                                              viewHeight: self.previewView.frame.height,
                                                              apperance: self.overlayApperance)
                self.handoverImagetoDeletate(originalFrame: pixelBuffer, croppedImage: croppedImage ?? UIImage())
            }
        } else {
            handoverImagetoDeletate(originalFrame: pixelBuffer, croppedImage: convertedImage)
            
        }
    }
    
    public func handoverImagetoDeletate(originalFrame: CVPixelBuffer, croppedImage: UIImage) {
        if toBeSendInDelegate == true {
            DispatchQueue.main.async {
                self.delegate?.captured(originalframe: originalFrame, overlayFrame: self.outterWhiteRectView.frame, croppedImage: croppedImage)
            }
        } else {
            captureDelegate?.readData(originalframe: originalFrame, croppedFrame: croppedImage.toPixelBuffer())
        }
    }
    
    /** Calls methods to update overlay view with detected bounding boxes and class names.
     */
    public func draw(objectOverlays: [ObjectOverlay]) {
        //print("&&&&&& &&&&&&& &&&&&&& OBJECT OVERLAY",objectOverlays)
        self.overlayView.objectOverlays = objectOverlays
        
        self.overlayView.clipsToBounds = true
        self.overlayView.setNeedsDisplay()
    }
    
    public func isQrLongDistance(image:UIImage,previewWidth:CGFloat,previewHeight:CGFloat) ->Bool {
        let isLong = LongDistance().isLongDistanceQRImage(cropImageWidth: image.size.width, cropImageHeight: image.size.height, previewWidth: previewWidth, previewHeight: previewHeight)
        return isLong
    }
    
    public func isBarcodeLongDistance(image:UIImage,previewWidth:CGFloat,previewHeight:CGFloat) ->Bool {
        let isLong = LongDistance().isLongDistanceBarcodeImage(cropImageWidth: image.size.width, cropImageHeight: image.size.height, previewWidth: previewWidth, previewHeight: previewHeight)
        return isLong
    }
    
    public func getValidBarCode(_ codeFormat: Int) -> String {
        
        let codes = ["Aztec", "CODABAR", "Code 39", "Code 93", "Code 128",
                     "Data Matrix", "EAN-8", "EAN-13", "ITF", "MaxiCode",
                     "PDF417", "QR Code", "RSS 14", "RSS EXPANDED", "UPC-A",
                     "UPC-E", "UPC/EAN"]
        
        if codeFormat < codes.count {
            return codes[codeFormat]
        } else {
            return "QR Code"
        }
        
    }
    
    public  func getCurrentMillis() -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MMM-dd HH:mm:ss.SSSS"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    ///   - buffer: The BGRA pixel buffer to convert to RGB data.
    ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
    ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`.
    ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
    ///       floating point values).
    ///   - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
    ///     converted.
    
    public func rgbDataFromBuffer(
        _ buffer: CVPixelBuffer,
        byteCount: Int,
        isModelQuantized: Bool,
        imageMean : Float,
        imageStd: Float
    ) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        }
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width
        
        var sourceBuffer = vImage_Buffer(data: sourceData,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: sourceBytesPerRow)
        
        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            SFManager.shared.print(message: "Error: out of memory", function: .rgbDataFromBuffer)
            return nil
        }
        
        defer {
            free(destinationData)
        }
        
        var destinationBuffer = vImage_Buffer(data: destinationData,
                                              height: vImagePixelCount(height),
                                              width: vImagePixelCount(width),
                                              rowBytes: destinationBytesPerRow)
        
        if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA){
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        } else if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32ARGB) {
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        }
        
        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        if isModelQuantized {
            return byteData
        }
        
        // Not quantized, convert to floats
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for byte in 0..<bytes.count {
            floats.append((Float(bytes[byte]) - imageMean) / imageStd)
        }
        return Data(copyingBufferOf: floats)
    }
    
    public func decryptFile(key: String, nonce: String, data: Data) -> Data? {
        let keyData = Data(hexString: key)!
        let ivData = Data(hexString: nonce)!
        let decryptedData = data
        var decryptedDataCopy = decryptedData
        var decryptedDataLength: Int = 0
        
        let status = keyData.withUnsafeBytes { keyBytes in
            ivData.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    decryptedDataCopy.withUnsafeMutableBytes { decryptedDataBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            decryptedDataBytes.baseAddress, decryptedData.count,
                            &decryptedDataLength
                        )
                    }
                }
            }
        }
        
        if status == kCCSuccess {
            decryptedDataCopy.removeSubrange(decryptedDataLength..<decryptedData.count)
            return decryptedDataCopy
        } else {
            return nil
        }
    }

    public func encrypt(data: Data, keyData: String, ivData: String) throws -> Data {
        let key = Data(hexString: keyData)!
        let iv = Data(hexString: ivData)!
        let encryptedData = Data(count: data.count + kCCBlockSizeAES128)
        var encryptedDataCopy = encryptedData
        var encryptedDataLength: Int = 0

        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    encryptedDataCopy.withUnsafeMutableBytes { encryptedDataBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, kCCKeySizeAES128,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            encryptedDataBytes.baseAddress, encryptedData.count,
                            &encryptedDataLength
                        )
                    }
                }
            }
        }

        if status == kCCSuccess {
            encryptedDataCopy.removeSubrange(encryptedDataLength..<encryptedData.count)
            return encryptedDataCopy
        } else {
            throw NSError(domain: "EncryptionError", code: Int(status), userInfo: nil)
        }


    }

}


extension ScanflowCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @objc
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            SFManager.shared.print(message: error.localizedDescription, function: .longDistance)
        } else {
            SFManager.shared.print(message: "Your image has been saved to your photos. \(contextInfo.debugDescription)", function: .imageSaved)
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        SFManager.shared.config.frameCount += 1
        
        if SFManager.shared.config.frameCount < 5 {
            return
        }
        
        // Converts the CMSampleBuffer to a CVPixelBuffer.
        
        SFManager.shared.print(message: "SFManager: Sample buffer to Pixel buffer", function: .captureOutput)
        ///Enable or disable debug with test images can be handled here
        if isFrameProcessing == false {
            if scannerType != .tire, scannerType != .containerVertical, scannerType != .containerHorizontal, scannerType != .dotTire, scannerType != .docuementScaning {
                isFrameProcessing = true
            }
           // if ScanflowLicenseManager.shared.licenceValidaded == true {
                isDebuggingImagesCMSampleBuffer(Scanflow.DebugMode.sampleBufferWithTestImages, sampleBuffer)
          //  }
        }
        
        
    }
    
     func isDebuggingImagesCMSampleBuffer(_ isWithTestImages: Bool, _ sampleBuffer: CMSampleBuffer) {
        
        switch isWithTestImages {
        case false:
            let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
            
            guard let imagePixelBuffer = pixelBuffer else {
                return
            }

            scanningDetails.orginalImage = imagePixelBuffer.toImage()
            lowLightHandler(imagePixelBuffer, sampleBuffer)
            
        default:
            let testImage = UIImage(named: "testBar")
            let pixelBuffer = testImage?.toPixelBuffer()
            guard let imagePixelBuffer = pixelBuffer else {
                return
            }
            
            lowLightHandler(imagePixelBuffer, sampleBuffer)
            
        }
         
     }

}

extension ScanflowCameraManager : CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentCoordinates = locations.last
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(error.localizedDescription)
    }
    
}
