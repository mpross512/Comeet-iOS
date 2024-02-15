//
//  UserService.swift
//  Comeet
//
//  Created by Michael Ross on 11/14/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation

@Observable
class UserService {
    
    func likeUser(uid: String) {
//        print("DEBUG: Calling function with user \(user.id) and target \(uid)")
//        Functions.functions().httpsCallable("likeUser").call(["user": user.id, "target": uid]) { result, error in
//            if let error = error as NSError? {
//                print("ERROR: \(error.code) \(error.localizedDescription) \(error.description) \(error.userInfo[FunctionsErrorDetailsKey]!)")
//            } else {
//                print("DEBUG: \(result!)")
//            }
//        }
    }
    
    func uploadNewImage(path: String) {
//        let localURL = URL(string: path)!
//        let profilePicReference = Constants.Database.profilePicsRef.child("\(user.id).jpeg")
//            
//        profilePicReference.putFile(from: localURL, metadata: nil) { metadata, error in
//            if let error = error {
//                print(error)
//            }
//        }
    }
        
    func uploadNewImage(data: Data) {
//        let profilePicReference = Constants.Database.profilePicsRef.child("\(user.id).jpeg")
//        
//        print("DEBUG: Profile picture reference is \(profilePicReference)")
//        profilePicReference.putData(data, metadata: nil) { metadata, error in
//            if let error = error {
//                print("DEBUG: \(error)")
//            }
//        }
    }
}
