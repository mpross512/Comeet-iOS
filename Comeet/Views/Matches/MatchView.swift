//
//  HomeView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import SwiftUIBackports

struct MatchView: View {
    
    @EnvironmentObject var userService: UserService
    
    init() {
        //print("DEBUG: Matches: ")
        //print(userService.user.matches)
    }
    
    var body: some View {
        
        NavigationView {
            if !userService.isLoading {
                List(userService.matches) { match in
                    HStack {
                        NavigationLink {
                            UserView(user: match)
                        } label: {
                            HStack {
                                ProfilePicture(profileURL: match.pictureRef, width: 50, height: 50)
                                VStack (alignment: .leading) {
                                    Text("\(match.name["first"] ?? ""), \(match.getAge())")
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.animation(.easeIn(duration: 5)))
                .navigationBarTitle("Matches", displayMode: .large)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}
