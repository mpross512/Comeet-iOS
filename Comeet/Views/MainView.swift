//
//  MainView.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct MainView: View {
        
    @ObservedObject var authenticator = UserAuthenticator.getUserAuthenticator()
    
    var body: some View {
        
        ZStack {
            if authenticator.isSignedIn() {
                
                VStack {
                
                    Text("Hello, World!")
                        .padding()
                    
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            self.authenticator.refresh()
                        } catch {
                            print(error)
                        }
                    }) {
                        Text("Sign Out")
                    }
                }
                
            } else {
                
                InitialView()
                
            }
        }
        
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
