//
//  UserView.swift
//  Comeet
//
//  Created by Michael Ross on 11/16/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import WrappingHStack

struct UserView: View {

    var user: any Person
    @Environment(UserService.self) var userService: UserService
    @Environment(User.self) var currentUser: User
    @State private var likeError: String?
    @State private var isLiking = false

    private var isLiked: Bool { currentUser.likes.contains(user.id) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProfilePicture(userID: user.id, width: 175, height: 175)
                    .accessibilityHidden(true)

                UserBio(user: user)

                UserInterests(attributes: user.attributes)

                likeControl
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle(user.firstName)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: isLiked) { wasLiked, liked in !wasLiked && liked }
        .alert("Could not like profile", isPresented: Binding(get: { likeError != nil }, set: { if !$0 { likeError = nil } })) {
            Button("OK") { likeError = nil }
        } message: { Text(likeError ?? "") }
    }

    @ViewBuilder
    private var likeControl: some View {
        if isLiked {
            Label("You liked \(user.firstName)", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 50)
        } else {
            Button {
                like()
            } label: {
                Label(isLiking ? "Liking…" : "Like \(user.firstName)", systemImage: "heart")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 34)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Constants.Colors.greenColor)
            .disabled(isLiking)
        }
    }

    private func like() {
        guard !isLiking else { return }
        isLiking = true
        Task {
            defer { isLiking = false }
            if await userService.likeUser(userID: currentUser.id, matchID: user.id) {
                if !currentUser.likes.contains(user.id) { currentUser.likes.append(user.id) }
            } else {
                likeError = userService.errorMessage
            }
        }
    }
}

struct UserInterests: View {
    
    var attributes: [Attribute]
    
    var body: some View {
        WrappingHStack(attributes.filter { $0.importance >= 3 && !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { attribute in
            UserInterest(text: attribute.value, emoji: attribute.name)
                .padding(5)
        }.padding(10)
    }
}

struct UserInterest: View {
    
    let text: String
    let emoji: String
    
    var body: some View {
        
        Text("\(Constants.Values.emojis[emoji] ?? "") \(text)")
            .font(.subheadline)
            .padding(8)
            .background (
                Capsule()
                    .fill(Color.green.opacity(0.3))
            )
        
    }
}

#Preview {
    NavigationStack {
        UserView(user: PreviewModels.previewUser.matches.first!)
    }
    .environment(SessionStore.shared)
    .environment(UserService())
    .environment(PreviewModels.previewUser)
}
