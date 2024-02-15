//
//  ChatView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct ChatView: View {
    @Environment(User.self) var currentUser: User
    var messageService = MessageService()
    @State var conversations = [Conversation]()
    @State var loading = true
    
    var body: some View {
        ZStack {
            NavigationStack {
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
                                Text("\(match.firstName), \(match.age)")
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.large)
            }
            if(loading) {
                ProgressView()
                    .controlSize(.extraLarge)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color.white)
            }
        }.task {
            conversations = await Conversation.all(userID: currentUser.id)
            loading = false
        }
    }
}
