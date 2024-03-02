//
//  Chat.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import Realtime

@Observable
class Conversation: Identifiable, Decodable, Hashable {
    var id: Int
    var recipientID: UUID = UUID()
    var messages = [Message]()
    
    private var members = [UUID]()
    
    static func all(userID: UUID) async -> [Conversation] {
        var conversations: [Conversation] = []
        let supabase = Supabase.shared
        
        do {
            conversations = try await supabase.database
                .from("conversations")
                .select("*, conversation_members(member_id), messages(*), users!inner()")
                .eq("users.id", value: userID)
                .or("public.eq.true,recipient_id.eq.\(userID),sender.eq.\(userID)", referencedTable: "messages")
                .execute()
                .value
                        
            var conversationIDString = "("
            for conversation in conversations {
                conversation.recipientID = conversation._members.first(where: {$0 != userID})!
                conversationIDString.append("\(conversation.id),")
            }
            let idString = "\(conversationIDString[...conversationIDString.index(before: conversationIDString.lastIndex(of: ",")!)]))"
                
            Task { [conversations] in
                let channel = await supabase.realtime.channel("public:messages")
                let messageInsertions =  await channel.postgresChange(InsertAction.self, schema: "public", table: "messages", filter: "conversation_id=in.\(idString)")
                //let updates = await channel.postgresChange(AnyAction.self, schema: "public", table: "messages", filter: nil)
                
                await channel.subscribe()
                                
                Task {
                    for await insertion in messageInsertions {
                        print(insertion.record)
                        do {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ"
                            let decoder = JSONDecoder()
                            decoder.dataDecodingStrategy = .base64
                            decoder.dateDecodingStrategy = .formatted(formatter)
                            let message = try insertion.decodeRecord(decoder: decoder) as Message
                            conversations.first(where: {$0.id == message.conversationID})!.messages.append(message)
                        } catch {
                            print(error)
                        }
                    }
                }
                
//                Task {
//                    for await update in updates {
//                        print(update.rawMessage)
//                    }
//                }
            }
            
        } catch {
            print("ERROR: \(error)")
        }
        
        return conversations
    }
    
    enum CodingKeys: String, CodingKey {
        case members = "conversation_members"
        case id
        case messages
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.members = []
        let members = try container.decode([[String:UUID]].self, forKey: .members)
        for member in members {
            for memberID in member.values {
                self.members.append(memberID)
            }
        }
        self.messages = try container.decode([Message].self, forKey: .messages)
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
