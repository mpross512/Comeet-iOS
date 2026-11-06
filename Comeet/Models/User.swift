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
class User : Identifiable, Person {
    
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
        likes = record.likedUserIds
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
    }
    
}
