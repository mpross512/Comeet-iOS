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
    }
    
    func isSignedIn() -> Bool {
        return signedIn
    }
    
}
