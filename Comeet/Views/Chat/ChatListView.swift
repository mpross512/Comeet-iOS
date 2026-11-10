//
//  ChatListView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import Shimmer
import ComeetData

/// Loads the chat list when the app becomes active and on pull to refresh. The list does not poll;
/// an open chat polls its own conversation (see `MessageView`).
@MainActor @Observable
final class ChatListState {
    private(set) var conversations: [Conversation] = []
    private(set) var loading: Bool
    var errorMessage: String?
    private let repository: any ComeetRepository
    private let handleError: @MainActor (any Error) -> Void

    init(loading: Bool = true,
         repository: any ComeetRepository = APIConfiguration.client,
         handleError: @escaping @MainActor (any Error) -> Void = { SessionStore.shared.handle($0) }) {
        self.loading = loading
        self.repository = repository
        self.handleError = handleError
    }

    /// Most recent activity first. Computed so a reply sent from an open chat reorders the list.
    var ordered: [Conversation] { conversations.sorted { $0.lastActivityID > $1.lastActivityID } }

    func load() async {
        guard !Task.isCancelled else { return }
        do {
            let loaded = try await Conversation.all(repository: repository, reusing: conversations)
            try Task.checkCancellation()
            conversations = loaded
            errorMessage = nil
            loading = false
        } catch {
            guard !Task.isCancelled,
                  !(error is CancellationError),
                  (error as? URLError)?.code != .cancelled else { return }
            handleError(error)
            loading = false
            errorMessage = error.localizedDescription
        }
    }
}

struct ChatView: View {
    @State private var state = ChatListState()
    @Environment(User.self) private var currentUser
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.large)
        }
        // Runs when the tab first appears and whenever the app returns to the foreground.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await state.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.loading {
            LoadingChatView()
        } else if state.conversations.isEmpty {
            ScrollView {
                if let error = state.errorMessage {
                    ContentUnavailableView {
                        Label("Couldn’t Load Chats", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try Again") { Task { await state.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView("No Chats Yet", systemImage: "bubble.left.and.bubble.right",
                                           description: Text("When you and a match both like each other, your chat will appear here."))
                }
            }
            .defaultScrollAnchor(.center)
            .refreshable { await state.load() }
        } else {
            List(state.ordered) { conversation in
                NavigationLink {
                    MessageView(conversation: conversation)
                } label: {
                    ChatRow(conversation: conversation, currentUserID: currentUser.id)
                }
            }
            .refreshable { await state.load() }
            .alert("Couldn’t Refresh Chats",
                   isPresented: Binding(get: { state.errorMessage != nil }, set: { if !$0 { state.errorMessage = nil } })) {
                Button("Try Again") { Task { await state.load() } }
                Button("OK", role: .cancel) { }
            } message: { Text(state.errorMessage ?? "") }
        }
    }
}

struct ChatRow: View {
    let conversation: Conversation
    let currentUserID: UUID
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the avatar moves above the text so names keep the full row width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            ProfilePicture(userID: conversation.peer.id, width: 50, height: 50)
            VStack(alignment: .leading, spacing: 2) {
                if dynamicTypeSize.isAccessibilitySize {
                    name
                    time
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        name
                        Spacer()
                        time
                    }
                }
                Text(MessageText.preview(of: conversation.messages.last, peer: conversation.peer, currentUserID: currentUserID))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                if conversation.openPrompt != nil {
                    Text("Your turn")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Constants.Colors.orangeTextBackgroundColor, in: Capsule())
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var name: some View {
        Text(conversation.peer.fullName).font(.headline)
    }

    @ViewBuilder
    private var time: some View {
        if let last = conversation.messages.last {
            Text(last.timestamp.formatted(.relative))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct LoadingChatView: View {
    var body: some View {
        List(0..<4, id: \.self) { _ in
            HStack(spacing: 12) {
                Circle().fill(.quaternary).frame(width: 50, height: 50)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("First Last").font(.headline)
                        Spacer()
                        Text("Mon").font(.subheadline)
                    }
                    Text("Latest message preview text that wraps").font(.subheadline).lineLimit(2)
                }
            }
            .padding(.vertical, 4)
            // Applied per row: masking the whole List would also hide its large title.
            .redacted(reason: .placeholder)
            .shimmering()
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading chats")
    }
}
