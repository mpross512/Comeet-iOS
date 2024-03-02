//
//  MessageService.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation

class MessageService: ObservableObject {
    
    func addMessage(conversationID: Int, messageID: Int, response: String) async {
        let supabase = Supabase.shared
                
        do {
            print("Inserting message with conversation id \(conversationID) and response \(response)")
            
            let params = AddMessageParams(conversation_id: conversationID, sender: try await supabase.auth.user().id, text: response)
            
            try await supabase.database
                .from("messages")
                .insert(params)
                .execute()
        } catch {
            print(error)
        }
        
    }
}

struct AddMessageParams: Codable {
    var conversation_id: Int
    var sender: UUID
    var text: String
    var response_option: [String] = []
    var `public` = true
}
