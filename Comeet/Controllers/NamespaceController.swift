//
//  NamespaceController.swift
//  Comeet
//
//  Created by Michael Ross on 3/12/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

@Observable class NamespaceController {
    
    internal init(matchCard: Namespace.ID = Namespace().wrappedValue) {
        self.matchCard = matchCard
    }
    
    let matchCard:Namespace.ID
}
