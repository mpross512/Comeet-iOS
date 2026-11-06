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
    @Environment(SessionStore.self) var session
    var user = User()
    @State var emailConfirmed = false
    @State var loading = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var loadError: String?
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
                                        MatchCardView(match: match, animation: matchCardAnimation,
                                                      isSource: selectedUser?.id != match.id)
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
                                        MatchDetailView(match: selectedUser as! Match, animation: matchCardAnimation)
                                            .onTapGesture {
                                                withAnimation(.smooth) {
                                                    selectedUser = nil
                                                }
                                            }
                                            .transition(.scale(scale: 1))
                                    }
                                    if selectedUser != nil {
                                        UserBio(user: selectedUser as! Match, matchAnimation: matchCardAnimation)
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
        }.task(id: scenePhase) {
            guard scenePhase == .active else { return }
            do {
                emailConfirmed = try await session.repository.account().emailConfirmed
                try await session.reloadProfile()
                loading = false
            } catch { SessionStore.shared.handle(error); loading = false; loadError = error.localizedDescription }
        }.alert("Could not load matches", isPresented: Binding(get: { loadError != nil }, set: { if !$0 { loadError = nil } })) {
            Button("OK") { loadError = nil }
        } message: { Text(loadError ?? "") }
    }
}

struct MatchCardView: View {
    let animation: Namespace.ID
    let isSource: Bool
    
    var profileURL: URL
    var match: Match
    
    
    init(match: Match, animation: Namespace.ID, isSource: Bool) {
        self.animation = animation
        self.isSource = isSource
        self.match = match
        self.profileURL = APIConfiguration.photoURL(userID: match.id)
    }
    
    var body: some View {
        ZStack {
            WebImage(url: profileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                .matchedGeometryEffect(id: "\(match.id)-image", in: animation, isSource: isSource)
            LinearGradient(colors: [.clear, .clear, .clear, .black], startPoint: .top, endPoint: .bottom)
                .opacity(0.5)
            VStack {
                Spacer()
                HStack {
                    Text("**\(match.fullName),** \(match.age)")
                        .foregroundStyle(.white)
                        .font(.title)
                        .minimumScaleFactor(0.1)
                        .matchedGeometryEffect(id: "\(match.id)-name", in: animation, isSource: isSource)
                        //.padding(.leading)
                    Spacer()
                }
                HStack {
                    Text("Class of \(String(match.graduationYear))")
                        .foregroundStyle(.white)
                        .matchedGeometryEffect(id: "\(match.id)-year", in: animation, isSource: isSource)
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
    let animation: Namespace.ID
    @State var scrollPosition: Int?
    
    var profileURL: URL
    var match: Match
    
    init(match: Match, animation: Namespace.ID) {
        self.animation = animation
        self.match = match
        self.profileURL = APIConfiguration.photoURL(userID: match.id)
    }
    
    var body: some View {
        WebImage(url: profileURL)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .matchedGeometryEffect(id: "\(match.id)-image", in: animation)
    }
}

struct VerifyEmailView: View {
    @State private var emailSent = false
    @State private var sendError: String?
    
    var body: some View {
        VStack {
            Text("You can't receive matches until you have verified your email.").padding()
            Text("Didn't receive a verification email? Make sure to check your spam.").padding()
            if(!emailSent) {
                Button {
                    Task {
                        do {
                            let email = try await SessionStore.shared.repository.account().email
                            try await SessionStore.shared.repository.resendConfirmation(email: email)
                            emailSent = true
                        } catch { SessionStore.shared.handle(error); sendError = error.localizedDescription }
                    }
                } label: {
                    Text("Resend verification email").italic().padding()
                }
            }
            Text("Verification email sent").padding()
        }.alert("Could not send verification email", isPresented: Binding(get: { sendError != nil }, set: { if !$0 { sendError = nil } })) {
            Button("OK") { sendError = nil }
        } message: { Text(sendError ?? "") }
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
        .environment(SessionStore.shared)
        .environment(PreviewModels.previewUser)
}
