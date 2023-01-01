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
                    Text("You and \(user.name["first"] ?? "") both like each other!").italic().font(.caption).foregroundColor(.gray)
                }
                
                
            }.toolbar{
                ToolbarItem(placement: .principal) {
                    Text("\(user.name["first"] ?? "") \(user.name["last"] ?? "")").bold()
                }
            }
        
        
        
    }
}

struct IndividualMessage: View {
    var body: some View {
        Text("Individual Message")
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(user: User())
    }
}
