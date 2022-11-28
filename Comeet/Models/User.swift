//
//  User.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct User : Identifiable, Codable {
    @DocumentID var id: String?
    var year: Int
    var name: [String: String]
    var birthdate: String
    var major: String
    var bio: String
    var matches: [String]
    var pictureRef: URL?
    
    init() {
        year = 0
        name = [:]
        birthdate = ""
        major = ""
        bio = ""
        matches = []
        pictureRef = URL(string: "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png")!
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let newDate = dateFormatter.date(from: birthdate)
        let ageComponents = Calendar.current.dateComponents([.year], from: newDate!, to: Date())
        return ageComponents.year!
    }
}
