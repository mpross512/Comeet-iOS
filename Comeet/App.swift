//
//  App.swift
//  Comeet
//
//  Created by Michael Ross on 10/14/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI
import FirebaseCore

@main 
struct ComeetApp: App {
    @StateObject private var userService = UserService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MasterView().environmentObject(userService)
        }
    }
}
