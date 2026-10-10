//
//  HomeView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct MatchView: View {
    @Environment(User.self) var currentUser: User
    @Environment(Supabase.self) var supabase: Supabase
    var user = User()
    @State var emailConfirmed = false
    @State var loading = true
    @State var selectedUser: (any Person)? = nil
    @State var isZoomed = false
    
    @Namespace var matchCardAnimation
    
    var body: some View {
        ZStack {
            if(!emailConfirmed && !loading) {
                VerifyEmailView()
            } else {
                NavigationView {
                    ScrollView {
                        if currentUser.matches.isEmpty {
                            Text("No matches right now, check back on Monday!").italic()
                        }
                        if(loading) {
                            LoadingMatchView()
                        } else {
                            LazyVStack {
                                ForEach(currentUser.matches) { match in
                                    NavigationLink {
                                        UserView(user: match)
                                    } label: {
                                        MatchCardView(match: match)
                                            .onTapGesture {
                                                withAnimation(.snappy) {
                                                    selectedUser = match
                                                }
                                            }
                                    }
                                }
                            }
                            .navigationBarTitle("Matches", displayMode: .large)
                        }
                    }
                }
                .overlay {
                    if selectedUser != nil {
                        ZStack {
                            ScrollView {
                                VStack {
                                    if selectedUser != nil {
                                        MatchDetailView(match: selectedUser as! Match)
                                            .onTapGesture {
                                                withAnimation(.smooth) {
                                                    selectedUser = nil
                                                }
                                            }
                                            .transition(.scale(scale: 1))
                                    }
                                    if selectedUser != nil {
                                        UserBio(user: selectedUser as! Match)
                                            .background(RoundedRectangle(cornerRadius: 25.0).foregroundStyle(.white))
                                            .offset(y: -40)
                                            .transition(.move(edge: .bottom))
                                    }
                                }
                            }
                        }.ignoresSafeArea()
                            //.transition(.move(edge: .bottom))
                    }
                }
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

struct MatchCardView: View {
    @Environment(NamespaceController.self) var namespace
    
    var profileURL: URL
    var match: Match
    
    
    init(match: Match) {
        self.match = match
        do {
            self.profileURL = try Supabase.shared.storage
                .from("profile-pictures")
                .getPublicURL(path: "\(match.id.uuidString.lowercased()).jpeg")
        } catch {
            print("ERROR: \(error)")
            self.profileURL = URL(string: "")!
        }
    }
    
    var body: some View {
        ZStack {
            WebImage(url: profileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                .matchedGeometryEffect(id: "MatchImage", in: namespace.matchCard)
            LinearGradient(colors: [.clear, .clear, .clear, .black], startPoint: .top, endPoint: .bottom)
                .opacity(0.5)
            VStack {
                Spacer()
                HStack {
                    Text("**\(match.fullName),** \(match.age)")
                        .foregroundStyle(.white)
                        .font(.title)
                        .minimumScaleFactor(0.1)
                        .matchedGeometryEffect(id: "MatchName", in: namespace.matchCard)
                        //.padding(.leading)
                    Spacer()
                }
                HStack {
                    Text("Class of \(String(match.graduationYear))")
                        .foregroundStyle(.white)
                        .matchedGeometryEffect(id: "MatchYear", in: namespace.matchCard)
                    Spacer()
                    Text(match.major)
                        .foregroundStyle(.white)
                }
            }.padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 25.0))
        .padding()
    }
}

struct MatchDetailView: View {
    @Environment(NamespaceController.self) var namespace
    @State var scrollPosition: Int?
    
    var profileURL: URL
    var match: Match
    
    init(match: Match) {
        self.match = match
        do {
            self.profileURL = try Supabase.shared.storage
                .from("profile-pictures")
                .getPublicURL(path: "\(match.id.uuidString.lowercased()).jpeg")
        } catch {
            print("ERROR: \(error)")
            self.profileURL = URL(string: "")!
        }
    }
    
    var body: some View {
        WebImage(url: profileURL)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .matchedGeometryEffect(id: "MatchImage", in: namespace.matchCard)
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

struct LoadingMatchView: View {
    var body: some View {
        List {
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                Text("First Name, Age")
                    .padding(.leading)
            }
            HStack {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                Text("First Name, Age")
                    .padding(.leading)
            }
        }
        .redacted(reason: .placeholder)
        .navigationTitle("Matches")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    MatchView(emailConfirmed: true, loading: false)
        .environment(Supabase.shared)
        .environment(PreviewModels.previewUser)
}
