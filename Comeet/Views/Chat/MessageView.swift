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
                        IndividualMessage(message: message, match: recipient)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                if(!conversation.messages.isEmpty && !conversation.messages.last!.responseOptions.isEmpty) {
                    ResponseOptions(userID: currentUser.id, conversationID: conversation.id, messageID: conversation.messages.last!.id, responseOptions: conversation.messages.last!.responseOptions)
                        .padding(.bottom, 0.1)
                }
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
    var responseOptions: [String]
    @State var selectedResponse = ""
    @State var sendingResponse = false
    @State var dates = [
        Date(),
        Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
        Calendar.current.date(byAdding: .hour, value: 2, to: Date())!]

    var body: some View {
            HStack {
                ResponseOptionsList(responseOptions: responseOptions, selectedResponse: $selectedResponse, dates: $dates)
                Button {
                    Task {
                        sendingResponse = true
                        var response = selectedResponse
                        if(response == "{datetime_3}") {
                            response = "\(dates[0])|\(dates[1])|\(dates[2])"
                        }
                        await messageService.addMessage(
                            conversationID: conversationID,
                            messageID: messageID,
                            response: response)
                        sendingResponse = false
                        selectedResponse = ""
                    }
                } label: {
                    if sendingResponse {
                        ProgressView()
                            .foregroundStyle(.white)
                            .padding(10)
                            .background {
                                Circle()
                            }
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background {
                                Circle()
                            }
                    }
                }.disabled(selectedResponse == "")
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .stroke()
                    //.frame(minHeight: 50)
                    .foregroundStyle(.gray)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 25))
            }
            .padding()
            .background(.bar)
    }
}

struct ResponseOptionsList: View {
    var responseOptions: [String]
    @Binding var selectedResponse: String
    @State var popoverPresented = false
    @Binding var dates: [Date]

    var body: some View {
        WrappingHStack(responseOptions) { option in
            Button {
                if(selectedResponse == option) {
                    selectedResponse = ""
                } else {
                    selectedResponse = option
                }
                print("DEBUG: selected response: \(option)")
                if(selectedResponse == "{datetime_3}") {
                    var transaction = Transaction()
                    //transaction.disablesAnimations = true
                    
                    transaction.animation = .easeInOut(duration: 5)
                    withTransaction(transaction) {
                        popoverPresented = true
                    }
                }
            } label: {
                Text(option == "{datetime_3}" ? "3 Dates" : option)
                    .foregroundStyle(
                        selectedResponse == option ? Color.white : Color.black
                    )
                    .padding(10)
                    .background {
                        Capsule().stroke(Color.gray, lineWidth: selectedResponse == option ? 0 : 1).background {
                            Capsule().foregroundStyle(
                                selectedResponse == option ? Constants.Colors.orangeColor : Color.white
                            )
                        }
                    }
            }
            .padding(.vertical, 5)
            .fullScreenCover(isPresented: $popoverPresented) {
                DateTimePopover(dateOne: $dates[0], dateTwo: $dates[1], dateThree: $dates[2], selectedResponse: $selectedResponse)
                    .animation(.easeInOut(duration: 5), value: popoverPresented)
                    .presentationBackground(.thinMaterial)
            }
        }
    }
}

struct DateTimePopover: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var dateOne: Date
    @Binding var dateTwo: Date
    @Binding var dateThree: Date
    @Binding var selectedResponse: String
    
    var body: some View {
        VStack {
            Text("Please choose 3 times you would be available for a 1 hour date")
                .padding(.bottom)
            DatePicker("Date 1", selection: $dateOne, in: Date.now...)
                .labelsHidden()
            DatePicker("Date 2", selection: $dateTwo, in: Calendar.current.date(byAdding: .hour, value: 1, to: dateOne)!...)
                .labelsHidden()
            DatePicker("Date 3", selection: $dateThree, in: Calendar.current.date(byAdding: .hour, value: 1, to: dateTwo)!...)
                .labelsHidden()
            
            Button {
                var transaction = Transaction()
                //transaction.disablesAnimations = true
                
                withTransaction(transaction) {
                    dismiss()
                }
                
            } label: {
                Text("Save")
                    .foregroundStyle(.white)
                    .padding()
                    //.font(.title3)
                    .background {
                        Capsule(style: .circular)
                            .foregroundStyle(Constants.Colors.greenColor)
                    }
                    .padding(.top)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 25.0).foregroundStyle(Color.white)
        }
        .padding()
    }
}
    
struct IndividualMessage: View {
    var message: Message
    var comeetUID = Constants.Values.comeetUID
    @Environment(User.self) var currentUser: User
    var match: Match
    
    var body: some View {
        HStack {
            if message.sender == currentUser.id {
                Spacer()
            }
            VStack(alignment: message.sender != currentUser.id ? .leading : .trailing) {
                Text(formatText(text: message.text)).padding(10)
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
    
    func formatText(text: String) -> LocalizedStringKey {
        var result = text
        result = result.replacingOccurrences(of: "{user}", with: match.firstName)
        
        return LocalizedStringKey(result)
    }
}

#Preview{
    ZStack {
        Color.yellow
        ResponseOptions(messageService: MessageService(), userID: UUID(), conversationID: 1, messageID: 1, responseOptions: [
            "{datetime_3}", "No", "This is a super long response", "This is another super long response"
        ]).opacity(0.8)
        
    }
}
