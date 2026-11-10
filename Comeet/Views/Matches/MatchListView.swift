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
    @State private var refresh = MatchRefreshState()
    @Environment(\.scenePhase) private var scenePhase

    @Namespace private var matchTransition

    init(loading: Bool = true) {
        _refresh = State(initialValue: MatchRefreshState(loading: loading))
    }

    var body: some View {
        ZStack {
            if session.accountInfo?.emailConfirmed == false && !refresh.loading {
                VerifyEmailView()
            } else {
                NavigationStack {
                    ScrollView {
                        if refresh.loading {
                            LoadingMatchView()
                                .padding()
                        } else if currentUser.matches.isEmpty {
                            ContentUnavailableView(
                                "No Matches Yet",
                                systemImage: "person.2",
                                description: Text("Check back on Monday for your next match.")
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(currentUser.matches) { match in
                                    NavigationLink {
                                        UserView(user: match)
                                            .matchZoomTransition(id: match.id, in: matchTransition)
                                    } label: {
                                        MatchCardView(match: match)
                                            .matchTransitionSource(id: match.id, in: matchTransition)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                    .refreshable { await refresh.load(session: session) }
                    .navigationTitle("Matches")
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

private extension View {
    /// Zooms from the match card into the profile on iOS 18+, unless Reduce Motion is on.
    @ViewBuilder
    func matchZoomTransition(id: UUID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            modifier(MatchZoomTransition(id: id, namespace: namespace))
        } else {
            self
        }
    }

    @ViewBuilder
    func matchTransitionSource(id: UUID, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace) { $0.clipShape(.rect(cornerRadius: 25)) }
        } else {
            self
        }
    }
}

@available(iOS 18.0, *)
private struct MatchZoomTransition: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let id: UUID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        }
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let match: Match

    var body: some View {
        // The ZStack keeps a 4:5 photo card but grows when large text needs more room.
        ZStack(alignment: .bottom) {
            Color.clear.aspectRatio(4 / 5, contentMode: .fit)
            details
        }
        .background { MatchPhoto(userID: match.id) }
        .clipShape(.rect(cornerRadius: 25))
            .contentShape(.rect(cornerRadius: 25))
            .accessibilityElement(children: .combine)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("**\(match.fullName),** \(match.age)")
                .font(.title)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
            if dynamicTypeSize.isAccessibilitySize {
                Text("Class of \(String(match.graduationYear))")
                Text(match.major)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("Class of \(String(match.graduationYear))")
                    Spacer()
                    Text(match.major)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .padding(.top, 32)
        .background {
            LinearGradient(colors: [.black.opacity(0), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .accessibilityHidden(true)
        }
    }
}

/// A match's profile photo, with a neutral placeholder while it loads or when there is none.
struct MatchPhoto: View {
    let userID: UUID

    var body: some View {
        WebImage(url: APIConfiguration.photoURL(userID: userID))
            .placeholder { placeholder }
            .resizable()
            .scaledToFill()
            .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(uiColor: .secondarySystemFill))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(.tertiary)
            }
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
        guard !busy, !(Date() < resendAvailableAt) else { return }
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
        RoundedRectangle(cornerRadius: 25)
            .fill(Color(uiColor: .secondarySystemFill))
            .aspectRatio(4 / 5, contentMode: .fit)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Last, 20").font(.title)
                    Text("Class of 2026")
                }
                .padding()
            }
            .redacted(reason: .placeholder)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading matches")
    }
}

#Preview {
    MatchView(loading: false)
        .environment(SessionStore.shared)
        .environment(PreviewModels.previewUser)
}
