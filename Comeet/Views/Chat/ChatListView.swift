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
    @Environment(User.self) var currentUser: User
    var messageService = MessageService()
    @State var conversations: [Conversation] = [Conversation(), Conversation()]
    @State var loading = true
    
    var body: some View {
        NavigationStack {
            if(loading) {
                LoadingChatView()
            } else {
                List(conversations) { conversation in
                    HStack {
                        if let match = currentUser.matches.first(where: { match in
                            match.id == conversation.recipientID
                        }) {
                            NavigationLink{
                                MessageView(conversation: conversation)
                                    .navigationTitle("\(match.fullName)")
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                ProfilePicture(userID: match.id, width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(match.firstName)
                                            .padding(.leading)
                                            .font(.headline)
                                        Spacer()
                                        Text(conversation.messages.last?.timestamp.formatted(.relative) ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.thin)
                                    }
                                    Text(conversation.messages.last?.text ?? "")
                                        .padding(.leading)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .task {
            conversations = await Conversation.all(userID: currentUser.id)
            loading = false
        }
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
