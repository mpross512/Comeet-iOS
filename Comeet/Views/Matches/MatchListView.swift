//
//  HomeView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct MatchView: View {
    
    @EnvironmentObject var userService: UserService
    
    init() {
        //print("DEBUG: Matches: ")
        //print(userService.user.matches)
    }
    
    var body: some View {
        if(userService.isAuthenticated && !Auth.auth().currentUser!.isEmailVerified) {
            VerifyEmailView()
        } else {
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
                        if userService.matches.isEmpty {
                            Text("No matches right now, check back on Monday!").italic()
                        }
                    }
                    .transition(.opacity.animation(.easeIn(duration: 5)))
                    .navigationBarTitle("Matches", displayMode: .large)
                }
            }
        }
    }
}

struct VerifyEmailView: View {
    @State private var responseText: String = ""
    
    var body: some View {
        VStack {
            Text("You can't receive matches until you have verified your email.").padding()
            Text("Didn't receive a verification email? Make sure to check your spam.").padding()
            Button (action:{
                Auth.auth().currentUser?.sendEmailVerification() { error in
                    if let error {
                        responseText = error.localizedDescription
                    } else {
                        responseText = "Verification email sent"
                    }
                }
            }) {
                Text("Resend verification email").italic().padding()
            }
            Text(responseText).padding()
            
            
        }
    }
}

#Preview {
    MatchView()
}
