//
//  Constants.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI

struct Constants {
    
    struct Database {
        
        let users = "users"
                
        static let supabaseStorageURL = "https://bikoswjhsmcbwricdpyv.supabase.co/storage/v1/object/public/"
        
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
            "exercise": "🏋️",
            "lovelanguage": "💑",
            "socialmedia": "📱",
            "diet": "🍴"
        ]
        
        static let comeetUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    
    struct SetupQuestions {
        
        static let questions: [Question] = [
            Question(category: "religion", question: "Do you identify with a religion?", options: [
                "Agnostic", "Atheist", "Buddhist", "Catholic", "Christian", "Hindu", "Latter-day Saint", "Mormon", "Muslim", "Sikh", "Spiritual", "Zoroastrian", "Other"
            ]),
            Question(category: "children", question: "What are your plans for children?", options: [
                "Want", "Don't want", "Have and want more", "Have and don't want more", "Not sure yet"
            ]),
            Question(category: "politics", question: "What are your political leanings?", options: [
                "Conservative", "Liberal", "Moderate", "Don't care", "Other"
            ]),
            Question(category: "alcohol", question: "Do you drink?", options: [
                "Socially", "Frequently", "Sometimes", "Rarely", "Never", "Sober"
            ]),
            Question(category: "smoking", question: "Do you smoke?", options: [
                "Socially", "Frequently", "Sometimes", "Rarely", "Never", "Sober"
            ]),
            Question(category: "marriage", question: "What are your plans for marriage?", options: [
                "Want", "Don't want", "Not now, but later", "Not sure yet"
            ]),
            Question(category: "exercise", question: "Do you exercise?", options: [
                "Daily", "Weekly", "Monthly", "Never"
            ]),
            Question(category: "lovelanguage", question: "What is your love language?", options: [
                "Gifts", "Quality Time", "Physical Touch", "Words of Affirmation", "Acts of Service"
            ]),
            Question(category: "socialmedia", question: "Do you use social media?", options: [
                "Daily", "Weekly", "Monthly", "Never"
            ]),
            Question(category: "diet", question: "Do you have a certain diet?", options: [
                "Kosher", "Halal", "Vegan", "Vegetarian", "Other", "None"
            ])
        ]
        
        struct Question {
            var category: String
            var question: String
            var options: [String]
            
        }
    }
    
}
