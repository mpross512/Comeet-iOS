//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MessageView: View {
    
    init() {
        
    }
    
    var body: some View {

            VStack {
                ScrollView {
                    Text("Message View")
                }
            }.toolbar{
                ToolbarItem(placement: .principal) {
                    Text("Isabelle").font(.title).bold()
                }
            }
        
        
        
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView()
    }
}
