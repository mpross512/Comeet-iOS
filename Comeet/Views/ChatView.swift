//
//  ChatView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct ChatView: View {
    var body: some View {
        
        NavigationView {
            
            List(chats) { chat in
                HStack{
                    ProfilePicture(width: 50, height: 50)
                        .padding(.vertical, 5)
                    Text(chat.name)
                        .padding(.leading)
                }
            }
            
            
            
            .navigationBarTitle("Chat")
            .listStyle(GroupedListStyle())
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
}

let chats = [
    ChatRoom(id: "1", name: "Isabelle")
]
