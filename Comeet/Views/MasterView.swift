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
        
    @ObservedObject var authenticator = UserHandler.getUserHandler()
    
    var body: some View {
        
        ZStack {
            if authenticator.isSignedIn() {
                
                HomeView()
                
            } else {
                
                InitialView()
                
            }
        }
        
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MasterView()
    }
}
