//
//  UnitTestWithAWSTests.swift
//  UnitTestWithAWSTests
//
//  Created by ShaoJen Chen on 2020/8/25.
//  Copyright © 2020 ShaoJen Chen. All rights reserved.
//

import XCTest
@testable import UnitTestWithAWS

class UnitTestWithAWSTests: XCTestCase {
    
    let jsonString = """
{
  "Logs": [
    {
      "LogName": "A",
      "LogType": "Type1"
    },
    {
      "LogName": "B",
      "LogType": "Type2"
    }
  ]
}
"""
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    func testGetJsonFromAWS() throws {
            
            let e = expectation(description: "Alamofire")
            
            let fileID = "XXXXXX"
            
            AWSConnector.connector.getJsonFileFromAWS(qrcode: fileID) { (json,errorCode) in
                
                guard let json = json else { return }
                
                guard let fileResponse = AWSGetFileResponse(JSON: json) else { return }
                
                guard let file_base64_string = fileResponse.file_base64_string else { return }
                
                let key16bit = "1234123412341234"
                
                guard let plaintext = AESManager.manager.aesDecrypt(ciphertext: file_base64_string, key: key16bit) else { return }
                
                fileResponse.file_base64_string = plaintext
                
                guard let jsonString = fileResponse.toJSONString(prettyPrint: false) else { return }
                
                e.fulfill()
                
                debugPrint("Unit test done.")
                debugPrint("jsonString => \(jsonString)")
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
            
            //custom url
    //        AWSConnector.connector.getJsonFileFromAWS(AWSURL: "", qrcode: fileID) { (json,errorCode) in
    //        }
        }

        func testSetJsonToAWS() throws {
            
            let e = expectation(description: "Alamofire")
            
            let key16bit = "1234123412341234"
            
            guard let cipherText = AESManager.manager.aesEncrypt(plaintext: jsonString, key: key16bit) else { return }
            
            AWSConnector.connector.setJsonFileToAWS(ciphertext: cipherText) { (json, errorCode) in
                
                guard let json = json else { return }
                
                guard let result = json["result"] as? String,
                    result == "success" else { return }
                
                let fileID = json["file_id"] as! String
                
                e.fulfill()
                
                debugPrint("Unit test done.")
                debugPrint("fileID => \(fileID)")
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)

    //        //custom url
    //        AWSConnector.connector.setJsonFileToAWS(AWSURL: "", ciphertext: cipherText) { (json, errorCode) in
    //        }
        }
}
