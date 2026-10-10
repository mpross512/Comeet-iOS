//
//  Match.swift
//  Comeet
//
//  Created by Michael Ross on 2/14/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation
import ComeetData

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
        case attributes
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
    
    init(record: PersonRecord) throws {
        id = record.id; firstName = record.firstName; lastName = record.lastName
        birthdate = try WireDates.birthday(record.birthdate)
        graduationYear = record.graduationYear; major = record.major; bio = record.bio
        attributes = record.attributes.map { Attribute(name: $0.name, importance: $0.importance, value: $0.value) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(WireDates.birthday(birthdate), forKey: .birthdate)
        try container.encode(graduationYear, forKey: .graduationYear)
        try container.encode(major, forKey: .major)
        try container.encode(bio, forKey: .bio)
        try container.encode(attributes, forKey: .attributes)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.graduationYear = try container.decode(Int.self, forKey: .graduationYear)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.birthdate = try WireDates.birthday(container.decode(String.self, forKey: .birthdate))
        self.major = try container.decode(String.self, forKey: .major)
        self.bio = try container.decode(String.self, forKey: .bio)
        self.attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes) ?? []
    }
}
