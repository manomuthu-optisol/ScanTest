//
//  ViewController.swift
//  NewLicencing
//
//  Created by Mac-OBS-32 on 15/09/22.
//

import UIKit
import Security
import SystemConfiguration
//import AppCenter
//import AppCenterCrashes
//import AppCenterAnalytics

@objc public enum CaptureType: Int {
    case barcodeCapture
    case textCapture
    case idCapture
    case documentCapture
}

class ScanflowLicenseManager: NSObject {
    
    static public let shared = ScanflowLicenseManager()
    
    //Licence based keys
    let reachability = try? Reachability()
    let aesKey = "FiugQTgPNwCWUY,VhfmM4cKXTLVFvHFe"
#if DEBUG
    let stringLicenseValidationURL = "https://scanflowdev.azurewebsites.net/LicenseKey/ValidateLicenseKey"
#else
    let stringLicenseValidationURL = "https://scanflowprod.azurewebsites.net/LicenseKey/ValidateLicenseKey"
#endif
    private var strAuthKey = ""

    let scanFlowIntegrationKey = "KeyForPassword"
    let scanFlowSubscriptionEndDate = "subscriptionEndDate"
    let scanFlowSubscriptionStartDate = "subscriptionStartDate"
    let scanFlowRecevingDateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    let scanFlowConvertingDateFormat = "MMM dd,yyyy"
    let scanFlowLocalValidationkey = "Approved"
    var licenceValidaded: Bool = false
    var previewView: UIView?
    var outerWhiteRectView: UIView?
    
    struct ValidationModel: Codable {
        let deviceMake: String
        let deviceModel: String
        let osVersion: String
        let bundleId: String
        let productType: String
        let deviceUId: String
        let platform: String
    }
    // MARK: - ValidateResponseDetails
    struct ValidateResponseDetails: Codable {
        let status, message: String?
        let result: ValidateResponseResult?
    }
    
    // MARK: - ValidateResponseResult
    

    // MARK: - Result
    struct ValidateResponseResult: Codable {
        let active: Bool
        let lastSyncDate: String
        let isPackageExeed: Bool
        let subscriptionStartDate, subscriptionEndDate, packageName, analyticsID: String
        let scanType: [String]

        enum CodingKeys: String, CodingKey {
            case active, lastSyncDate, isPackageExeed, subscriptionStartDate, subscriptionEndDate, packageName
            case analyticsID = "analytics_Id"
            case scanType = "scan_Type"
        }
    }
    
    public func validateLicense(key: String, productType: String) {

        strAuthKey = key
        if KeychainService.loadPassword(passwordKey: scanFlowIntegrationKey) != key {
            KeychainService.clearEntireKeychain()
        }
        isvalidatingLicense(isBoolInternet: isInternetAvailable(), productType: productType)
    }
    
    private func isInternetAvailable() -> Bool {
        var zeroAddress: sockaddr_in6 = sockaddr_in6()
        zeroAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        zeroAddress.sin6_family = sa_family_t(AF_INET6)
         let routeReachability = withUnsafePointer(to: &zeroAddress) { sfPointer in
            sfPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }
        
        guard let defaultRouteReachability = routeReachability else {
            return false
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    
    // MARK:  this method user for validating the license in local and api
    func isvalidatingLicense(isBoolInternet : Bool, productType: String) {
        
        if let subscriptionStartDate = getDateFromString(string: KeychainService.loadPassword(passwordKey: scanFlowSubscriptionStartDate)), let subscriptionEndDate = getDateFromString(string: KeychainService.loadPassword(passwordKey: scanFlowSubscriptionEndDate))  {
            validateLicense(licenceStartDate: subscriptionStartDate, licenceEndDate: subscriptionEndDate, isSyncBool: true, productType: productType)
        } else {
            if isBoolInternet {
                getValidationSubscriptionDataUsingApi(productType: productType)
            } else {
                debugPrint("First time installation you need to enable internet")
                self.showToast(message: "First time installation you need to enable internet", boolToastRemove: true)
            }
        }
        
    }
    
    // MARK:  this method user for check the validation date with current date
    func validateLicense(licenceStartDate : Date ,licenceEndDate : Date ,isSyncBool : Bool, productType: String) {
        var currentDate = Date()
        if #available(iOS 15, *) {
            currentDate = Date.now
        } else {
            currentDate = Date()
        }
        
        guard let subscriptionStartDate = getDateFromString(string: KeychainService.loadPassword(passwordKey: scanFlowSubscriptionStartDate)) else {
            return
        }
        guard let subscriptionEndDate = getDateFromString(string: KeychainService.loadPassword(passwordKey: scanFlowSubscriptionEndDate)) else {
            return
        }
       
        
        if licenceStartDate > currentDate {
            self.licenceValidaded = false
            debugPrint("Invalid License licenceValidaded")
                self.getValidationSubscriptionDataUsingApi(productType: productType)
            
            
        } else if  currentDate > licenceEndDate {
            self.licenceValidaded = false
            debugPrint("Invalid LicensecurrentDate")
                self.getValidationSubscriptionDataUsingApi(productType: productType)
            
        } else {
            self.licenceValidaded = true
            SFManager.shared.configureAnalytic(analyticId: UserDefaults.standard.string(forKey: "analyticId") ?? "")
            debugPrint("Valid License licenceValidaded = true")
            
        }
    }
    // MARK:  this method Hitting the api and get the proper response
    func getValidationSubscriptionDataUsingApi(productType: String) {
        self.showToast(message: "Please wait, Validating license!", boolToastRemove: true)
        guard let url = URL(string: stringLicenseValidationURL) else {
            print("Error: cannot create URL")
            return
        }
        // Add data to the model

        let uploadDataModel = ValidationModel(deviceMake: UIDevice.current.model, deviceModel: UIDevice.current.name, osVersion: UIDevice.current.systemVersion, bundleId: Bundle.main.bundleIdentifier!, productType: productType, deviceUId: UIDevice.current.identifierForVendor!.uuidString, platform: "iOS")
        // Convert model to JSON data
        guard let jsonData = try? JSONEncoder().encode(uploadDataModel) else {
            print("Error: Trying to convert model to JSON data")
            
            return
        }
        var request = URLRequest(url: url)
        print("url \(request), json: \(uploadDataModel)")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // the request is JSON
        request.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
        request.setValue(strAuthKey, forHTTPHeaderField: "AuthKey")
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else {
                return
            }
//            let data = Data()
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                debugPrint("Invalid Authkey")
                self.showToast(message: "Invalid Authkey", boolToastRemove: true)
                return
            }
            do {
                let gitData = try JSONDecoder().decode(ValidateResponseDetails.self, from: data)
                debugPrint("response data:", gitData)
                if let analyticId = gitData.result?.analyticsID {
                    SFManager.shared.saveAnalytic(id: analyticId)
                    
                }
                if gitData.status == "Success" {
                    guard let  subscriptionStartDate = gitData.result?.subscriptionStartDate as? String else {
                        return
                    }
                    guard let  subscriptionEndDate = gitData.result?.subscriptionEndDate else {
                        return
                    }
                    // this below two variable are used for validate the license
                    let licenceStartDate = self.getFormattedDate(string: subscriptionStartDate)
                    let licenceEndDate = self.getFormattedDate(string: subscriptionEndDate)
                    // save the api data into keychain services
                    KeychainService.savePassword(token: self.strAuthKey , passwordKey: self.scanFlowIntegrationKey)
                    print("password saved in keychain: \(KeychainService.loadPassword(passwordKey: self.scanFlowIntegrationKey))")
                    KeychainService.savePassword(token: self.getFormattedDateString(string: subscriptionStartDate), passwordKey: self.scanFlowSubscriptionStartDate)
                    KeychainService.savePassword(token: self.getFormattedDateString(string: subscriptionEndDate), passwordKey: self.scanFlowSubscriptionEndDate)
                    // this below Method call is used for date validation checking process
                    self.validateLicense(licenceStartDate: licenceStartDate, licenceEndDate: licenceEndDate, isSyncBool: false, productType: productType)
                } else {
                    self.showToast(message: gitData.message ?? "", boolToastRemove: true)
                    debugPrint(gitData.status as Any)
                    debugPrint(gitData.message as Any)
                }
            } catch let err {
                print("Err", err)
                self.showToast(message: err.localizedDescription, boolToastRemove: false)
            }
            
        }.resume()
    }
    
    func showToast(message : String ,boolToastRemove : Bool) {
        DispatchQueue.main.async(execute: {
            if let refLabel = self.previewView?.viewWithTag(999) as? UILabel {
                refLabel.removeFromSuperview()
            }
            let widthOfview = self.outerWhiteRectView?.frame ?? .zero
            let xPostitionOfView = self.outerWhiteRectView?.frame.origin ?? .zero
            
            let fontData = UIFont.systemFont(ofSize: 25, weight: UIFont.Weight.medium)
            let heightOfView = message.heightWithConstrainedWidth(width: widthOfview.width, font: fontData)
            let toastLabel = UILabel(frame: CGRect(
                x: xPostitionOfView.x,
                y: ((xPostitionOfView.y) + (widthOfview.height / 2) - (heightOfView / 2)),
                width: widthOfview.width, height: heightOfView))
            toastLabel.tag = 999
            toastLabel.textColor = UIColor.white
            toastLabel.font = fontData
            toastLabel.textAlignment = .center;
            toastLabel.text = message
            toastLabel.alpha = 1.0
            toastLabel.numberOfLines = 0
            toastLabel.layer.cornerRadius = 10;
            toastLabel.clipsToBounds  = true
         
            self.previewView?.addSubview(toastLabel)
            self.previewView?.bringSubviewToFront(toastLabel)
            if boolToastRemove == true {
                UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
                    toastLabel.alpha = 0.0
                }, completion: {(isCompleted) in
                    toastLabel.removeFromSuperview()
                })
            }
        })
    }
    
    // MARK:  this method used for convert the stringDate into  Date
    func getFormattedDate(string: String) -> Date{
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = scanFlowRecevingDateFormat
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = scanFlowConvertingDateFormat
        let date: Date? = dateFormatterGet.date(from: string)
        return date!
    }
    
    // MARK: this method used for convert the Date into  String
    func getFormattedDateString(string: String) -> String{
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = scanFlowRecevingDateFormat
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = scanFlowRecevingDateFormat
        let date: Date? = dateFormatterGet.date(from: string)
        return dateFormatterPrint.string(from: date!);
    }
    
    // MARK:  this method used for convert the stringlocalsavedate into Date Format
    func getDateFromString(string : String?) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = scanFlowRecevingDateFormat
        guard let stringData = string else { return nil}
        let date = dateFormatter.date(from: stringData)
        return date
    }
}


extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
}
