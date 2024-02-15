//
//  MessageService.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation

class MessageService: ObservableObject {
    
    func addMessage(userID: String, conversationID: String, messageID: Int, response: String) {
//        functions.httpsCallable("sendMessage").call(["content": response, "userID": userID, "conversationID": conversationID, "messageID": messageID]) { result, error in
//            if let error = error as NSError? {
//                if error.domain == FunctionsErrorDomain {
//                    let code = FunctionsErrorCode(rawValue: error.code)
//                    let message = error.localizedDescription
//                    let details = error.userInfo[FunctionsErrorDetailsKey]
//                    print("DEBUG: \(String(describing: code)) \(message) \(String(describing: details))")
//                }
//            }
//            if let data = result?.data as? [String: Any], let text = data["data"] as? String {
//            print("DEBUG: " + text)
//            }
//        }
    }
}
