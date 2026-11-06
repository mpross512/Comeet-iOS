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
}
