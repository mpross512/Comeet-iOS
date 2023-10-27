//
//  ChatView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct ChatView: View {
    
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        
        NavigationView {
            List(userService.matches) { match in
                if match.likes.contains(userService.user.id!) && userService.user.likes.contains(match.id!) {
                    HStack {
                        NavigationLink(destination: MessageView(user: match)) {
                            
                            ProfilePicture(profileURL: match.pictureRef, width: 50, height: 50)
                            
                            Text("\(match.name["first"] ?? ""), \(match.getAge())")
                                .padding(.leading)
                        }
                    }
                }
            }
            .navigationBarTitle("Chat", displayMode: .large)
            //.listStyle(GroupedListStyle())
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

struct ChatRoom : Identifiable{
    let id: String
    let name: String
    let uid: String
}

let chats = [
    ChatRoom(id: "1", name: "Isabelle", uid: "")
]
