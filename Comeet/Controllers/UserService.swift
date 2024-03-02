//
//  UserService.swift
//  Comeet
//
//  Created by Michael Ross on 11/14/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import Storage

@Observable
class UserService {
    
    func likeUser(userID: UUID, matchID: UUID) async -> Bool {
        let supabase = Supabase.shared
        
        do {
            try await supabase.database
                .rpc("like_user", params: ["userid": userID, "match": matchID])
                .execute()
            return true
        } catch {
            print(error)
        }
        
        return false
    }
        
    func uploadNewImage(data: Data) async {
        let supabase = Supabase.shared
        
        do {
            try await supabase.storage
                .from("profile-pictures")
                .update(
                    path: supabase.auth.user().id.uuidString.lowercased(),
                    file: data,
                    options: FileOptions(
                        upsert: true
                    )
                )
        } catch {
            print(error)
        }
    }
}
