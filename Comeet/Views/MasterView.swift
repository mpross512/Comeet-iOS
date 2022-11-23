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
            if Auth.auth().currentUser != nil  {
                HomeView()
            } else {
                InitialView()
            }
        }.onAppear {
            Task {
                if Auth.auth().currentUser != nil {
                    await userService.getUser(uid: Auth.auth().currentUser!.uid)
                }
            }
        }
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MasterView()
    }
}
