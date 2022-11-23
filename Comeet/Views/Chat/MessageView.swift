//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct MessageView: View {
    
    @State var user: User
    
    var body: some View {

            VStack {
                ScrollView {
                    Text("Message View")
                }
                
                
            }.toolbar{
                ToolbarItem(placement: .principal) {
                    Text("\(user.name["first"] ?? "") \(user.name["last"] ?? "")").bold()
                }
            }
        
        
        
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(user: User())
    }
}
