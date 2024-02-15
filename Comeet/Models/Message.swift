//
//  Message.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct Message: Codable, Identifiable {
    var id: Int = 0
    var timestamp: Date = Date()
    var text: String = ""
    var sender: UUID = UUID()
    var responseOptions: [String] = []
    var isPublic = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp = "created_at"
        case text
        case sender
        case responseOptions = "response_option"
        case isPublic = "public"
    }
}
