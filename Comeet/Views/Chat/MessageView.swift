//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import WrappingHStack

struct MessageView: View {
    @Environment(User.self) var currentUser: User
    var conversation: Conversation
    @State var recipient = Match()
    
    var body: some View {
        VStack {
            ScrollView {
//                Text("You and \(recipient.name["first"] ?? "") both liked each other!")
//                    .font(.caption).italic().foregroundStyle(Color.gray)
                ForEach(conversation.messages) { message in
                    if(message.sender == currentUser.id || message.isPublic) {
                        IndividualMessage(message: message)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            if(!conversation.messages.isEmpty && !conversation.messages.last!.responseOptions.isEmpty) {
                WrappingHStack(conversation.messages.last!.responseOptions, alignment: .trailing) { option in
                    ResponseOptions(userID: currentUser.id, conversationID: conversation.id, messageID: conversation.messages.last!.id, responseOption: option)
                }.padding(.trailing, 8)
            }
        }
        .task {
            self.recipient = currentUser.matches.first(where: {$0.id == conversation.recipientID})!
        }
    }
}

struct ResponseOptions: View {
    var messageService = MessageService()
    var userID: UUID
    var conversationID: Int
    var messageID: Int
    var responseOption: String
    var body: some View {
        Button {
            Task {
                await messageService.addMessage(conversationID: conversationID, messageID: messageID, response: responseOption)
            }
        } label: {
            Text(responseOption)
                .foregroundStyle(Color.black)
                .padding(10)
                .background {
                    Capsule().stroke(Color.gray, lineWidth: 2)
                }
        }
    }
}

struct IndividualMessage: View {
    var message: Message
    var comeetUID = Constants.Values.comeetUID
    @Environment(User.self) var currentUser: User
    
    var body: some View {
        HStack {
            if message.sender == currentUser.id {
                Spacer()
            }
            VStack(alignment: message.sender != currentUser.id ? .leading : .trailing) {
                Text(message.text).padding(10)
                    .foregroundStyle(Color.white)
                    .background {
                        RoundedRectangle(cornerRadius: 20).foregroundColor(message.sender != currentUser.id ? Constants.Colors.greenColor : Constants.Colors.orangeColor)
                    }
                Text(message.timestamp.formatted()).font(.caption2).foregroundStyle(Color.gray)
            }.padding(.horizontal, 8)
            if message.sender != currentUser.id {
                Spacer()
            }
        }
    }
}

//#Preview {
//    MessageView(match: User())
//}
