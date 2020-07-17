//
//  UserAuthenticator.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseAuth

class UserAuthenticator : ObservableObject {
    
    static private var singleton: UserAuthenticator?
    
    @Published private var signedIn: Bool = false
    
    private var profilePicReference = Constants.Database.profilePicsRef.child("\(Auth.auth().currentUser?.uid ?? "default").jpeg")
    
    private var imageURL: URL?
    
    init(_ signedIn: Bool) {
        self.signedIn = signedIn
    }
    
    static func getUserAuthenticator() -> UserAuthenticator {
        
        if singleton == nil {
            singleton = UserAuthenticator(Auth.auth().currentUser != nil)
        }
        return singleton!
        
    }
    
    func refresh() {
        signedIn = Auth.auth().currentUser != nil
        profilePicReference = Constants.Database.profilePicsRef.child("\(Auth.auth().currentUser?.uid ?? "default").jpeg")
        profilePicReference.downloadURL { (url, error) in
            if let e = error {
                print(e)
            } else {
                self.imageURL = url!
            }
        }
        
        print("Refreshing.... User ID is \(Auth.auth().currentUser?.uid ?? "nil")")
    }
    
    func isSignedIn() -> Bool {
        return signedIn
    }
    
    func getImageURL() -> URL? {
        profilePicReference = Constants.Database.profilePicsRef.child("\(Auth.auth().currentUser?.uid ?? "default").jpeg")
        if let imageURL = imageURL {
            print("Returned URL: \(imageURL)")
        }
        return imageURL
    }
    
}
