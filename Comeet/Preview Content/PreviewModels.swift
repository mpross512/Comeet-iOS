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
            user.id = UUID(uuidString: "572a669b-19c7-49ae-bc15-b16a6052b056")!
            user.firstName = "Michael"
            user.lastName = "Ross"
            user.major = "Computer Science"
            user.matches = []
            
            var match = Match()
            match.id = UUID(uuidString: "a0c4d737-bd2e-4720-b566-4fcde298cb73")!
            match.firstName = "Isabelle"
            match.lastName = "Ross"
            match.birthdate = formatter.date(from: "2000/10/31")!
            match.graduationYear = 2023
            match.major = "Computer Science"
            user.matches.append(match)
            
            return user
        }
    }
}
