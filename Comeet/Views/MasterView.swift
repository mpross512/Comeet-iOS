//
//  MainView.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MasterView: View {
    @Environment(SessionStore.self) var session
    var authenticated: Bool
    
    var body: some View {
        
        ZStack {
            if authenticated  {
                HomeView()
            } else {
                InitialView()
            }
        }.accentColor(Constants.Colors.orangeColor)
    }
}

#Preview {
    MasterView(authenticated: true)
}
