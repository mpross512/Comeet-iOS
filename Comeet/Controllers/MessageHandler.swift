//
//  MessageHandler.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseFunctions

class MessageService: ObservableObject {
    
    var functions: Functions
    
    init() {
        functions = Functions.functions()
    }
    
    func testFunction() {
//        functions.httpsCallable("helloWorld").call { result, error in
//            print("DEBUG: Result: \(String(describing: result))")
//            print("DEBUG: Error: \(String(describing: error))")
//        }
        
        
        functions.httpsCallable("addmessage").call(["text": "this is a test"]) { result, error in
          if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
              let code = FunctionsErrorCode(rawValue: error.code)
              let message = error.localizedDescription
              let details = error.userInfo[FunctionsErrorDetailsKey]
            }
          }
          if let data = result?.data as? [String: Any], let text = data["text"] as? String {
            print("DEBUG: " + text)
          }
        }
    }
    
}
