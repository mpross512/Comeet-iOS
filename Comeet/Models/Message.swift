//
//  Message.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import ComeetData

struct Message: Codable, Identifiable {
    var id: Int = 0
    var timestamp: Date = Date()
    var text: String = ""
    var sender: UUID = UUID()
    var responseOptions: [String] = []
    var isPublic = false
    var conversationID: Int
    
    init(record: MessageRecord) {
        id = record.id; timestamp = record.timestamp; text = record.text; sender = record.sender
        responseOptions = record.responseOptions; isPublic = record.isPublic; conversationID = record.conversationID
    }

    init(id: Int = 0, timestamp: Date = .now, text: String = "", sender: UUID = UUID(),
         responseOptions: [String] = [], isPublic: Bool = false, conversationID: Int) {
        self.id = id; self.timestamp = timestamp; self.text = text; self.sender = sender
        self.responseOptions = responseOptions; self.isPublic = isPublic; self.conversationID = conversationID
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp = "created_at"
        case text
        case sender
        case responseOptions = "response_option"
        case isPublic = "public"
        case conversationID = "conversation_id"
    }
}
