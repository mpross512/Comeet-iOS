//
//  App.swift
//  Comeet
//
//  Created by Michael Ross on 10/14/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI
import Supabase

@main 
struct ComeetApp: App {
    
    @State private var userService = UserService()
    @State private var currentUser = User()
    private var supabase = Supabase.shared
    
    var body: some Scene {
        WindowGroup {
            MasterView()
                .environment(userService)
                .environment(currentUser)
                .environment(supabase)
                .task {
                    self.currentUser = await User.currentUser
                }
        }
    }
}
