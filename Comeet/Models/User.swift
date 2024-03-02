//
//  User.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation

@Observable
class User : Identifiable, Codable, Person {
    
    // MARK: - Properties
    var id: UUID
    var graduationYear: Int
    var firstName: String
    var lastName: String
    var birthdate: Date
    var major: String
    var bio: String
    var matches: [Match]
    var attributes: [Attribute]
    var likes: [UUID]
    var conversations: [String]
    
    var fullName: String { return "\(self.firstName) \(self.lastName)"}
    
    var age: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let ageComponents = Calendar.current.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year!
    }
    
    // MARK: - Methods
    
    private static var _currentUser: User? = nil
    static var currentUser: User {
        get async {
            if(_currentUser == nil) {
                let supabase = Supabase.shared
                
                do {
                    _currentUser = try await supabase.database
                        .from("users")
                        .select("""
                                *,
                                conversations(id),
                                user_matches!user_matches_user_id_fkey(
                                    ...users!user_matches_match_id_fkey(*)
                                ),
                                user_likes!public_user_likes_user_id_fkey(
                                    ...users!public_user_likes_like_id_fkey(id)
                                ),
                                v_user_attributes(
                                    name,
                                    value,
                                    importance
                                )
                                """)
                        .eq("id", value: supabase.auth.session.user.id)
                        //.eq("user_matches.user_id", value: supabase.auth.session.user.id)
                        .single()
                        .execute()
                        .value
                    
                    return _currentUser!
                } catch {
                    print("ERROR: Supabase decoding error: \(error)")
                }
            } else {
                return _currentUser!
            }
            return User()
        }
    }
    
    init() {
        id = UUID()
        graduationYear = 0
        firstName = ""
        lastName = ""
        birthdate = Date()
        major = ""
        bio = ""
        matches = []
        attributes = []
        likes = []
        conversations = []
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case graduationYear = "graduation_year"
        case firstName = "first_name"
        case lastName = "last_name"
        case birthdate
        case major
        case bio
        case matches = "user_matches"
        case attributes = "v_user_attributes"
        case likes = "user_likes"
        case conversations = "conversations"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.graduationYear = try container.decode(Int.self, forKey: .graduationYear)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.birthdate = formatter.date(from: try container.decode(String.self, forKey: .birthdate)) ?? Date()
        self.major = try container.decode(String.self, forKey: .major)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.attributes = try container.decode([Attribute].self, forKey: .attributes)
        let likeResults = try container.decode([[String:UUID]].self, forKey: .likes)
        var likeIDs: [UUID] = []
        for dict in likeResults {
            for value in dict.values {
                likeIDs.append(value)
            }
        }
        self.likes = likeIDs
        let conversationResults = try container.decode([[String:Int]].self, forKey: .conversations)
        var conversationIDs: [String] = []
        for dict in conversationResults {
            for value in dict.values {
                conversationIDs.append(String(value))
            }
        }
        self.conversations = conversationIDs
        self.matches = try container.decode([Match].self, forKey: .matches)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(graduationYear, forKey: .graduationYear)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(birthdate, forKey: .birthdate)
        try container.encode(major, forKey: .major)
        try container.encode(bio, forKey: .bio)
        //try container.encode(matchIDs, forKey: .matchIDs)
        //try container.encode(attributes, forKey: .attributes)
        //try container.encode(likes, forKey: .likes)
        try container.encode(conversations, forKey: .conversations)
    }
}
