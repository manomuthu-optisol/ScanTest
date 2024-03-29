//
//  KeyChainService.swift
//  OptiAESComponents
//
//  Created by Mac-OBS-32 on 23/08/22.
//
import Foundation
import Security

// Constant Identifiers
let userAccount = "AuthenticatedUser"
let accessGroup = "SecuritySerivice"


/**
 *  User defined keys for new entry
 *  Note: add new keys for new secure item and use them in load and save methods
 */

//let passwordKey = "KeyForPassword"

// Arguments for the keychain queries
let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format: kSecAttrService)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

public class KeychainService: NSObject {

    /**
     * Exposed methods to perform save and load queries.
     */

    public class func savePassword(token: String ,passwordKey : String) {
        self.save(service: passwordKey , data: token)
    }

    public class func loadPassword(passwordKey : String) -> String? {
        return self.load(service: passwordKey)
    }
    
    /**
     * Internal methods for querying the keychain.
     */

    public class func clearEntireKeychain() {
        let query = [kSecClass: kSecClassGenericPassword] as CFDictionary

        let status = SecItemDelete(query)

        if status == errSecSuccess {
            print("Keychain cleared successfully.")
        } else {
            print("Unable to clear Keychain. Status: \(status)")
        }
    }

    
    private class func save(service: String, data: String) {
        if let data = data.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: service,
                kSecValueData as String: data]
            
            SecItemDelete(query as CFDictionary)
            
            let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
            debugPrint(status)
        }
    }

    private class func load(service: String) -> String? {
        let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecReturnData as String: kCFBooleanTrue!,
                kSecAttrAccount as String:service,
                kSecMatchLimit as String: kSecMatchLimitOne ]

            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

            if status == errSecSuccess, let retrievedData = dataTypeRef as? Data  {
                   let retrievedString = String(data: retrievedData, encoding: .utf8)
                    return retrievedString
            } else {
                return nil
            }
    }
    
     
}
