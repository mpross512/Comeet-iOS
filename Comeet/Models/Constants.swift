//
//  Constants.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI
import FirebaseStorage

struct Constants {
    
    struct Database {
        
        let users = "users"
        
        static let profilePicsRef = Storage.storage().reference().child("profilePictures")
        
    }
    
    struct Colors {
        
        static let yellowOrangeColor = Color(red: 0.95, green: 0.61, blue: 0.07, opacity: 1.00)
        static let greenColor = Color(red: 0.07, green: 0.28, blue: 0.20, opacity: 1.00)
        static let orangeColor = Color(red: 0.91, green: 0.46, blue: 0, opacity: 1.00)
        
    }
    
    struct Values {
        static let degrees = [
            "Accounting",
            "Actuarial Science",
            "American Studies",
            "Applied Cognition and Nueroscience",
            "Applied Sociology",
            "Art History",
            "Arts Technology and Emerging Communication",
            "Audiology",
            "Biochemistry",
            "Bioinformatics and Computational Biology",
            "Biology",
            "Biomedical Engineering",
            "Biotechnology",
            "Business Administration",
            "Business Analytics",
            "Chemistry",
            "Child Learning and Development",
            "Cognition and Nueroscience",
            "Cognitive Science",
            "Computer Engineering",
            "Computer Science",
            "Criminology",
            "Cyber Security, Technology and Policy",
            "Data Science",
            "Economics",
            "Education",
            "Electrical Engineering",
            "Energy Management",
            "Finance",
            "Financial Technology and Analytics",
            "Geosciences",
            "Geospatial Information Sciences",
            "Global Business",
            "Healthcare Leadership and Management",
            "Healthcare Management",
            "Healthcare Studies",
            "History",
            "History of Ideas",
            "Human Development and Early Childhood Disorders",
            "Human Resource Management",
            "Humanities",
            "Information Technology and Management",
            "Information Technology and Systems",
            "Innovation and Entrepenuership",
            "Interdisciplinary Studies",
            "International Management Studies",
            "International Political Economy",
            "Latin American Studies",
            "Leadership and Organizational Development",
            "Literature",
            "Management Science",
            "Marketing",
            "Materials Science and Engineering",
            "Mathematics",
            "Mathematics Education",
            "Mechanical Engineering",
            "Molecular and Cell Biology",
            "Molecular Biology",
            "Neuroscience",
            "Philosophy",
            "Physics",
            "Political Science",
            "Psychology",
            "Public Affairs",
            "Public Policy",
            "Public Policy and Political Economy",
            "Science Education",
            "Social Data Analytics and Research",
            "Sociology",
            "Software Engineering",
            "Speech Language and Hearing Sciences",
            "Speech-Language Pathology",
            "Statistics",
            "Supply Chain Management",
            "Systems Engineering and Management",
            "Telecommunications Engineering",
            "Visual and Performing Arts"
        ]
        
        static let emojis = [
            "religion": "🙏",
            "children": "👶",
            "politics": "⚖️",
            "alcohol": "🍺",
            "smoking": "🚬",
            "marriage": "💍",
            "height": "📏"
        ]
    }
    
    struct SetupQuestions {
        
        static let questions: [Question] = [
        
        ]
        
        struct Question {
            var category: String
            var options: [String]
            
        }
    }
    
}
