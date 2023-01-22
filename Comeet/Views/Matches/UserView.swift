//
//  UserView.swift
//  Comeet
//
//  Created by Michael Ross on 11/16/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import WrappingHStack

struct UserView: View {
    
    var user: User
    
    var body: some View {
        ScrollView {
            VStack {
                ProfilePicture(profileURL: user.pictureRef, width: 175, height: 175)
                UserBio(user: user)
                
                UserInterests(attributes: user.attributes)
                
                HStack {
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "x.circle").resizable().frame(width: 50, height: 50)
                    }
                    Spacer()
                    Button {
                        
                    } label: {
                        Image(systemName: "heart.circle").resizable().frame(width: 50, height: 50)
                    }
                    Spacer()
                }
            }
                        
            
        }
    }
}

struct UserInterests: View {
    
    @State var attributes: [String: Attribute]
    
    var body: some View {
        let values = attributes.map {$0.value}
        WrappingHStack(values) { attribute in
            if (attribute.importance >= 3) {
                UserInterest(text: attribute.value, emoji: attribute.name)
                    .padding(5)
            }
        }.padding(10)
    }
}

struct UserInterest: View {
    
    @State var text: String
    @State var emoji: String
    
    var body: some View {
        
        Text("\(Constants.Values.emojis[emoji] ?? "") \(text)")
            .font(.subheadline)
            .padding(8)
            .background (
                Capsule()
                    .fill(Color.green.opacity(0.3))
            )
        
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(user: User())
    }
}
