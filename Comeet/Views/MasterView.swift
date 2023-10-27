//
//  MainView.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct MasterView: View {
        
    @EnvironmentObject var userService: UserService
    @ObservedObject var authenticator = UserHandler.getUserHandler()
    
    var body: some View {
        
        ZStack {
            if userService.isAuthenticated  {
                HomeView()
            } else {
                InitialView()
            }
        }.onAppear {
            Task {
                if userService.isAuthenticated {
                    await userService.getUser(uid: Auth.auth().currentUser!.uid)
                }
            }
        }.accentColor(Constants.Colors.orangeColor)

    }
    
    
}

#Preview {
    MasterView()
}
