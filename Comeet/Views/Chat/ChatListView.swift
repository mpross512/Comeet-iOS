//
//  ChatView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import Shimmer

struct ChatView: View {
    @State var conversations: [Conversation] = []
    @State var loading = true
    @State private var loadError: String?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            if(loading) {
                LoadingChatView()
            } else {
                List(conversations) { conversation in
                    NavigationLink {
                        MessageView(conversation: conversation)
                            .navigationTitle(conversation.peer.fullName)
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        ProfilePicture(userID: conversation.peer.id, width: 50, height: 50)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(conversation.peer.firstName).padding(.leading).font(.headline)
                                Spacer()
                                Text(conversation.messages.last?.timestamp.formatted(.relative) ?? "")
                                    .font(.subheadline).fontWeight(.thin)
                            }
                            Text(conversation.messages.last?.text ?? "")
                                .padding(.leading).font(.subheadline).lineLimit(2)
                        }
                    }
                }
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            do {
                conversations = try await Conversation.all()
                loading = false
                while !Task.isCancelled {
                    for conversation in conversations { try await conversation.refresh() }
                    try await Task.sleep(for: .seconds(2))
                }
            } catch is CancellationError { }
            catch { SessionStore.shared.handle(error); loading = false; loadError = error.localizedDescription }
        }
        .alert("Could not load chats", isPresented: Binding(get: { loadError != nil }, set: { if !$0 { loadError = nil } })) {
            Button("OK") { loadError = nil }
        } message: { Text(loadError ?? "") }
    }
}

struct LoadingChatView: View {
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
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.large)
    }
}
