//
//  User.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseFirestore

class User : Codable {
    
    var year: Int
    var name: [String: String]
    var age: Int
    var major: String
    var bio: String
    
    init() {
        year = 0
        name = [:]
        age = 0
        major = ""
        bio = ""
    }
    
    func getName() -> String {
        return "\(name["first"] ?? "") \(name["last"] ?? "")"
    }
    
    func getFirstName() -> String {
        return name["first"] ?? ""
    }
    
    func getLastName() -> String {
        return name["last"] ?? ""
    }
    
    func getYear() -> Int {
        return year;
    }
    
    func getMajor() -> String {
        return major
    }
    
    func getBio() -> String {
        return bio;
    }
    
    func getAge() -> Int {
        return age;
    }
}
