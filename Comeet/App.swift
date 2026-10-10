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
    
    // MARK: - Properties
    
    // MARK: Environment Objects
    @Namespace private var matchCard
    @State private var currentUser = User()
    
    private var namespaceController:NamespaceController {
        NamespaceController(matchCard: matchCard)
    }
    private var userService = UserService()
    private var supabase = Supabase.shared
    
    // MARK: View Variables
    @State private var isLoading = true
    @State private var isAuthenticationStateKnown = false
    @State private var authenticated = false
    
    
    // MARK: - View
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isLoading && isAuthenticationStateKnown {
                    MasterView(authenticated: authenticated)
                        .environment(userService)
                        .environment(currentUser)
                        .environment(supabase)
                        .environment(namespaceController)
                        .zIndex(0)
                } else {
                    Color.orange.ignoresSafeArea(edges: .all)
                        .zIndex(1)
                }
            }.task {
                Task {
                    for await (event, session) in await supabase.auth.authStateChanges {
                        switch event.rawValue {
                        case "INITIAL_SESSION":
                            self.authenticated = session != nil
                        case "SIGNED_IN":
                            self.authenticated = true
                        case "SIGNED_OUT": fallthrough
                        default:
                            self.authenticated = false
                        }
                        print("DEBUG: authStateChange \(event.rawValue)")
                        if self.authenticated {
                            self.currentUser = await User.currentUser
                            print("DEBUG: CurrentUser loaded")
                        }
                        withAnimation(.easeInOut(duration: 10)) {
                            self.isAuthenticationStateKnown = true
                            self.isLoading = false
                        }
                        print("DEBUG: isLoading complete")
                    }
                }
            }
        }
    }
}
