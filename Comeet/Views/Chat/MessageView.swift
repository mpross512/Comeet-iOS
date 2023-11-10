//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseFunctions

struct MessageView: View {
    var messageService = MessageService()
    @State var user: User
    let messageList = [Message(id: "1", timeSent: "1", content: "Test Message 1", sender: "comeet"),
                       Message(id: "2", timeSent: "1", content: "Test Message 2", sender: "comeet")]
    
    var body: some View {
        VStack {
            List{
                Text("You and \(user.name["first"] ?? "") both like each other!").italic().font(.caption).foregroundColor(.gray)
                ForEach(messageList, id: \.id) { message in
                    IndividualMessage(text: message.content)
                }
            }
            Button {
                messageService.testFunction()
            } label: {
                Text("Test function")
            }
        }.toolbar{
            ToolbarItem(placement: .principal) {
                Text("\(user.name["first"] ?? "") \(user.name["last"] ?? "")").bold()
            }
        }
    }
}

struct IndividualMessage: View {
    var text: String
    
    var body: some View {
        HStack {
            Text(text).padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 20).foregroundColor(.blue)
                }
            Spacer()
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(user: User())
    }
}
