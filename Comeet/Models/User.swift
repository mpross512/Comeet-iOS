//
//  User.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation

struct User {
    
    var graduationYear: Int
    var name: String
    var age: Int
    var major: String
    
    mutating func setGraduationYear(year: Int) {
        graduationYear = year
    }
    
    mutating func setName(name: String) {
        self.name = name
    }
    
    mutating func setAge(age: Int) {
        self.age = age
    }
    
    mutating func setMajor(major: String) {
        self.major = major
    }
    
    
    
}
