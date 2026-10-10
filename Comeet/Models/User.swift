//
//  User.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import ComeetData

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
    
    @MainActor
    static var currentUser: User {
        get async throws { try User(record: await APIConfiguration.client.profile()) }
    }

    init(record: ProfileRecord) throws {
        id = record.id
        graduationYear = record.graduationYear
        firstName = record.firstName
        lastName = record.lastName
        birthdate = try WireDates.birthday(record.birthdate)
        major = record.major
        bio = record.bio
        matches = try record.matches.map { try Match(record: $0) }
        attributes = record.attributes.map { Attribute(name: $0.name, importance: $0.importance, value: $0.value) }
        likes = record.likes.map(\.id)
        conversations = record.conversations.map { String($0.id) }
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
        self.birthdate = try WireDates.birthday(container.decode(String.self, forKey: .birthdate))
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
        try container.encode(WireDates.birthday(birthdate), forKey: .birthdate)
        try container.encode(major, forKey: .major)
        try container.encode(bio, forKey: .bio)
        //try container.encode(matchIDs, forKey: .matchIDs)
        //try container.encode(attributes, forKey: .attributes)
        //try container.encode(likes, forKey: .likes)
        try container.encode(conversations, forKey: .conversations)
    }
}
