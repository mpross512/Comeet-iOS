//
//  HomeView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MatchView: View {
    @Environment(User.self) var currentUser: User
    @Environment(Supabase.self) var supabase: Supabase
    var user = User()
    @State var emailConfirmed = false
    @State var loading = true
    
    var body: some View {
        ZStack {
            if(!emailConfirmed) {
                VerifyEmailView()
            } else {
                NavigationView {
                    //                if currentUser.matches.isEmpty {
                    //                    Text("No matches right now, check back on Monday!").italic()
                    //                }
                    List(currentUser.matches) { match in
                        HStack {
                            NavigationLink {
                                UserView(user: match)
                            } label: {
                                HStack {
                                    ProfilePicture(userID: match.id, width: 50, height: 50)
                                    VStack (alignment: .leading) {
                                        Text("\(match.firstName), \(match.age)")
                                            .padding(.leading)
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.animation(.easeIn(duration: 5)))
                    .navigationBarTitle("Matches", displayMode: .large)
                }
            }
            
            if(loading) {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color.white)
            }
        }.task {
            do {
                emailConfirmed = try await supabase.auth.user().emailConfirmedAt != nil
                loading = false
            } catch {
                print(error)
            }
        }
    }
}

struct VerifyEmailView: View {
    @State private var emailSent = false
    
    var body: some View {
        VStack {
            Text("You can't receive matches until you have verified your email.").padding()
            Text("Didn't receive a verification email? Make sure to check your spam.").padding()
            if(!emailSent) {
                Button {
                    Task {
                        let email = try await Supabase.shared.auth.user().email
                        try await Supabase.shared.auth.resend(email: email!, type: .signup)
                        emailSent = true
                    }
                } label: {
                    Text("Resend verification email").italic().padding()
                }
            }
            Text("Verification email sent").padding()
            
            
        }
    }
}

#Preview {
    MatchView()
}
