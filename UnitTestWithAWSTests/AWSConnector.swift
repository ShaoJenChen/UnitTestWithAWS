//
//  AWSConnector.swift
//  photoLibraryAndQRcode
//
//  Created by ShaoJen Chen on 2018/4/19.
//  Copyright © 2018年 ShaoJenChen. All rights reserved.
//

import UIKit
import Alamofire

private let _connector = AWSConnector()

public class AWSConnector: NSObject {
    
    public class var connector: AWSConnector {
        
        return _connector
        
    }
    
    var sessionManager: SessionManager = {
        
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 50 //10
        
        configuration.timeoutIntervalForResource = 50 //10
        
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        
        sessionManager.delegate.sessionDidReceiveChallenge = { session, challenge in
            var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
            var credential: URLCredential?
            
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
                disposition = URLSession.AuthChallengeDisposition.useCredential
                credential = URLCredential(trust: trust)
            } else {
                if challenge.previousFailureCount > 0 {
                    disposition = .cancelAuthenticationChallenge
                } else {
                    credential = sessionManager.session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                    
                    if credential != nil {
                        disposition = .useCredential
                    }
                }
            }
            
            return (disposition, credential)
        }
        
        return sessionManager
        
    }()
    
    public func getJsonFileFromAWS(AWSURL: String = "https://amazonaws.com/dev/getfile/",
                                   qrcode: String,
                                   completion: @escaping ([String:Any]?,Int?) -> Void ) {
        
        sessionManager.request("\(AWSURL)\(qrcode)/").responseJSON(completionHandler: { response in
            
            if let statusCode = response.response?.statusCode {
                
                switch response.result {
                    
                case .success(let value):
                    
                    if let result = value as? [String: AnyObject] , statusCode == HTTPStatusCode.ok.rawValue {
                        
                        completion(result,nil)
                        
                    }
                        
                    else {
                        
                        completion(nil,statusCode)
                        
                    }
                    
                case .failure(let error):
                    
                    completion(nil,error._code)
                    
                }
                
            }
            else {
                
                completion(nil,HTTPStatusCode.forbidden.rawValue)
                
            }
        })
        
    }
    
    public func setJsonFileToAWS(AWSURL: String = "https://amazonaws.com/dev/setfile/",
                                 ciphertext: String,
                                 completion: @escaping ([String:Any]?,Int?) -> Void) {
        
        let deviceInfo = UIDevice.current.name
        
        let deviceType = "iOS" + UIDevice.current.systemVersion + "-" + UIDevice.current.modelName
        
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as! String
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        let appNameAndVersion = appName + appVersion
        
        let parameters = [
            "file_data"    : ciphertext,
            "device_info"  : deviceInfo,
            "device_type"  : deviceType,
            "app_version"  : appNameAndVersion
            ]

        self.sessionManager.request(AWSURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response: DataResponse<Any>) in
            
            switch response.result {
                
            case .success(let value):
                
                if let result = value as? [String: AnyObject] {
                    
                    completion(result,nil)
                    
                }
                
            case .failure(let error):
                
                completion(nil,error._code)
                
            }
            
        }
            
    }
        
}

enum HTTPStatusCode: Int {
    // 100 Informational
    case `continue` = 100
    case switchingProtocols
    case processing
    // 200 Success
    case ok = 200
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case iMUsed = 226
    // 300 Redirection
    case multipleChoices = 300
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect
    // 400 Client Error
    case badRequest = 400
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case payloadTooLarge
    case uriTooLong
    case unsupportedMediaType
    case rangeNotSatisfiable
    case expectationFailed
    case imATeapot
    case misdirectedRequest = 421
    case unprocessableEntity
    case locked
    case failedDependency
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    // 500 Server Error
    case internalServerError = 500
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended = 510
    case networkAuthenticationRequired
}

//MARK: - UIDevice extension
extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPhone11,2":                              return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
        case "iPhone11,8":                              return "iPhone XR"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                    return "iPad 5"
        case "iPad7,5", "iPad7,6":                      return "iPad 6"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
        case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
        case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
        case "AppleTV5,3":                              return "Apple TV"
        case "AppleTV6,2":                              return "Apple TV 4K"
        case "AudioAccessory1,1":                       return "HomePod"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}
