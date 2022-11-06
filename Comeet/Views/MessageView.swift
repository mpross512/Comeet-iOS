//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MessageView: View {
    var body: some View {
        
        
        
        HStack {
            Text("Title")
            ScrollView {
                Text("Message View")
            }
        }
        
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
