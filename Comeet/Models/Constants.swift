//
//  Constants.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI
import FirebaseStorage

struct Constants {
    
    
    
    struct Database {
        
        let users = "users"
        
        static let profilePicsRef = Storage.storage().reference().child("profilePictures")
        
    }
    
    struct Colors {
        
        static let yellowOrangeColor = Color(red: 0.95, green: 0.61, blue: 0.07, opacity: 1.00)
        static let greenColor = Color(red: 0.15, green: 0.68, blue: 0.38, opacity: 1.00)
        static let orangeColor = Color(red: 0.90, green: 0.49, blue: 0.13, opacity: 1.00)
        
    }
    
}
