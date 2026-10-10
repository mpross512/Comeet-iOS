//
//  PreviewModels.swift
//  Comeet
//
//  Created by Michael Ross on 3/10/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation

struct PreviewModels {
    
    static var previewUser: User {
        get {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            
            let user = User()
            user.id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            user.firstName = "Alex"
            user.lastName = "Example"
            user.major = "Computer Science"
            user.matches = []
            
            var match = Match()
            match.id = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
            match.firstName = "Jordan"
            match.lastName = "Example"
            match.birthdate = formatter.date(from: "2000/10/31")!
            match.graduationYear = 2023
            match.major = "Computer Science"
            user.matches.append(match)
            
            return user
        }
    }
}
