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
    @State private var refresh = MatchRefreshState()
    @Environment(\.scenePhase) private var scenePhase
    @State var selectedUser: (any Person)? = nil
    @State var isZoomed = false
    
    @Namespace var matchCardAnimation
    
    init(loading: Bool = true) {
        _refresh = State(initialValue: MatchRefreshState(loading: loading))
    }

    var body: some View {
        ZStack {
            if(session.accountInfo?.emailConfirmed == false && !refresh.loading) {
                VerifyEmailView()
            } else {
                NavigationView {
                    ScrollView {
                        if currentUser.matches.isEmpty {
                            Text("No matches right now, check back on Monday!").italic()
                        }
                        if(refresh.loading) {
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
            await refresh.load(session: session)
        }.alert("Could not load matches", isPresented: Binding(get: { refresh.errorMessage != nil }, set: { if !$0 { refresh.errorMessage = nil } })) {
            Button("OK") { refresh.errorMessage = nil }
        } message: { Text(refresh.errorMessage ?? "") }
    }
}

// Scene changes cancel SwiftUI's task. Cancellation keeps the current content/loading
// state; the next active scene starts a fresh load.
@MainActor @Observable
final class MatchRefreshState {
    private(set) var loading: Bool
    var errorMessage: String?

    init(loading: Bool = true) { self.loading = loading }

    func load(session: SessionStore) async {
        guard !Task.isCancelled else { return }
        errorMessage = nil
        do {
            try await session.refreshAccount()
            try Task.checkCancellation()
            try await session.reloadProfile()
            try Task.checkCancellation()
            loading = false
        } catch {
            guard !Task.isCancelled,
                  !(error is CancellationError),
                  (error as? URLError)?.code != .cancelled else { return }
            session.handle(error)
            loading = false
            errorMessage = error.localizedDescription
        }
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
    @Environment(SessionStore.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    var allowProfileSetup = false
    @State private var busy = false
    @State private var emailSent = false
    @State private var feedback: String?
    @State private var errorText: String?
    @State private var resendAvailableAt = Date.distantPast

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "envelope.badge").font(.system(size: 48)).foregroundStyle(Constants.Colors.orangeColor)
                    .accessibilityHidden(true)
                Text(session.accountInfo?.emailConfirmed == true ? "Email verified" : "Check your email")
                    .font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                if session.accountInfo?.emailConfirmed == true {
                    Text("Your email is verified. You’re ready to continue.")
                } else {
                    Text("Verify your email to receive matches.")
                    if let email = session.accountInfo?.email { Text(email).font(.headline).textSelection(.enabled) }
                    Text("Follow the link in your verification email, then return to Comeet. If you don’t see it, check your spam folder.")
                        .foregroundStyle(.secondary)
                    Button("Open Mail") {
                        if let url = URL(string: "message://") {
                            openURL(url) { accepted in
                                if !accepted { errorText = "Couldn’t open Mail. Open your email app to find your verification email." }
                            }
                        }
                    }.buttonStyle(AuthPrimaryButtonStyle())
                    Button("I’ve verified my email") { checkVerification(manual: true) }
                        .frame(maxWidth: .infinity, minHeight: 44).disabled(busy)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Button(context.date < resendAvailableAt ? "Resend available shortly" : "Resend email") { resend() }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .disabled(busy || context.date < resendAvailableAt)
                    }
                    if emailSent { Label("Verification email requested. Check your inbox.", systemImage: "checkmark.circle").foregroundStyle(.secondary) }
                }
                if busy { ProgressView("Checking…") }
                if let feedback { Text(feedback).font(.callout).foregroundStyle(.secondary) }
                if let errorText { AuthError(message: errorText) }
                if allowProfileSetup {
                    Button(session.accountInfo?.emailConfirmed == true ? "Continue to profile setup" : "Continue setting up my profile") {
                        session.showVerification = false
                    }.frame(maxWidth: .infinity, minHeight: 44).disabled(busy)
                }
            }.padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .tint(AuthAppearance.tint)
        .task { checkVerification(manual: false) }
        .onChange(of: scenePhase) { _, phase in if phase == .active { checkVerification(manual: false) } }
    }

    private func checkVerification(manual: Bool) {
        guard !busy else { return }
        busy = true; errorText = nil; feedback = nil
        Task {
            defer { busy = false }
            do {
                try await session.refreshAccount()
                if session.accountInfo?.emailConfirmed == true { dismiss() }
                else if manual { feedback = "Your email isn’t verified yet. Follow the link in your email, then try again." }
            } catch { errorText = authenticationError(error) }
        }
    }
    private func resend() {
        guard !busy, Date() >= resendAvailableAt else { return }
        busy = true; errorText = nil; feedback = nil; emailSent = false
        Task {
            defer { busy = false }
            do {
                try await session.refreshAccount()
                guard session.accountInfo?.emailConfirmed != true, let email = session.accountInfo?.email else { return }
                try await session.repository.resendConfirmation(email: email)
                emailSent = true
                resendAvailableAt = .now.addingTimeInterval(30)
            } catch { session.handle(error); errorText = authenticationError(error) }
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
    MatchView(loading: false)
        .environment(SessionStore.shared)
        .environment(PreviewModels.previewUser)
}
