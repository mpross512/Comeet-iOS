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
    
    var userInterests = ["🙏 Christian", "⚖️ Republican", "⏰ Long Term", "👶 Wants Children"]
    
    var body: some View {
        ScrollView {
            VStack {
                ProfilePicture(profileURL: user.pictureRef, width: 175, height: 175)
                UserBio(user: user)
                
                UserInterests(interests: userInterests)
                
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
    
    @State var interests: [String]
    
    var body: some View {
        WrappingHStack(interests) { interest in
            UserInterest(text: interest)
                .padding(5)
        }.padding(10)
    }
}

struct UserInterest: View {
    
    @State var text: String
    
    var body: some View {
        
        Text(text)
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
