//
//  TabView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    
    @State private var selectedTab = "home"
    
    var body: some View {

        TabView(selection: $selectedTab) {
            
            MatchView().tabItem {
                Image(systemName: "person.2.square.stack")
                Text("Home")
            }.tag("home")
            
            ChatView().tabItem {
                Image(systemName: "bubble.right")
                Text("Chat")
            }.tag("chat")
            
            ProfileView().tabItem {
                Image(systemName: "person")
                Text("Profile")
            }.tag("profile")
            
        }
        
    }
    
}

#Preview{
    HomeView()
}
