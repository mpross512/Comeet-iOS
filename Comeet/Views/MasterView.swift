//
//  MainView.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MasterView: View {
    @Environment(Supabase.self) var supabase: Supabase
    @State var authenticated: Bool = false
    
    var body: some View {
        
        ZStack {
            if authenticated  {
                HomeView()
            } else {
                InitialView()
            }
        }.onAppear {
            Task {
                for await (event, session) in await supabase.auth.authStateChanges {
                    switch event.rawValue {
                        case "INITIAL_SESSION":
                            self.authenticated = session != nil
                        case "SIGNED_IN":
                            self.authenticated = true
                        case "SIGNED_OUT":
                            self.authenticated = false
                        default:
                            print("Default case")
                            break
                    }
                }
            }
        }.accentColor(Constants.Colors.orangeColor)
    }
}

#Preview {
    MasterView()
}
