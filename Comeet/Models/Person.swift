//
//  Match.swift
//  Comeet
//
//  Created by Michael Ross on 2/11/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation

protocol Person: Codable, Identifiable {
    var id: UUID { get set }
    var firstName: String { get set }
    var lastName: String { get set }
    var bio: String { get set }
    var birthdate: Date { get set }
    var graduationYear: Int { get set }
    var major: String { get set }
    var fullName: String { get }
    var age: Int { get }
    var attributes: [Attribute] { get set }
}
