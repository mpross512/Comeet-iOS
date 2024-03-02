//
//  Match.swift
//  Comeet
//
//  Created by Michael Ross on 2/14/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation

struct Match: Person, Identifiable {
    public var id: UUID
    public var firstName: String
    public var lastName: String
    public var bio: String
    public var birthdate: Date
    public var graduationYear: Int
    public var major: String
    public var attributes: [Attribute]
    
    var fullName: String { return "\(self.firstName) \(self.lastName)"}
        
    var age: Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let ageComponents = Calendar.current.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year!
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case graduationYear = "graduation_year"
        case firstName = "first_name"
        case lastName = "last_name"
        case birthdate
        case major
        case bio
    }
    
    init() {
        self.id = UUID()
        self.firstName = ""
        self.lastName = ""
        self.bio = ""
        self.birthdate = Date()
        self.graduationYear = 0
        self.major = ""
        self.attributes = []
    }
    
    init(from decoder: Decoder) throws {
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
        self.attributes = []// try container.decode([String:Attribute].self, forKey: .attributes)
    }
}
