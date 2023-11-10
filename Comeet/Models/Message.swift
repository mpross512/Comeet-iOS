//
//  Message.swift
//  Comeet
//
//  Created by Michael Ross on 11/5/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation

struct Message: Codable, Identifiable {
    var id: String
    var timeSent: String
    var content: String
    var sender: String
    
}
