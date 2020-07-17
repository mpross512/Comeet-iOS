//
//  ProfileView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import SDWebImageSwiftUI

struct ProfileView: View {
    
    @State var isInEditMode: Bool = false
    @State var profilePicURL: URL?
    
    init() {
        UserAuthenticator.getUserAuthenticator().refresh()
    }
    
    var body: some View {
        
        NavigationView {
        
            VStack {
                NavigationLink(destination: ChatView(), isActive: $isInEditMode) { EmptyView() }
                
                ScrollView {
                
                    ProfilePicture()
                    
                    UserBio()
                    
                    SignOutButton()
                }
                    
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isInEditMode.toggle()
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.title)
                        .accentColor(Constants.Colors.greenColor)
                }
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

struct SignOutButton: View {
    var body: some View {
        Button(action: {
            do {
                try Auth.auth().signOut()
                UserAuthenticator.getUserAuthenticator().refresh()
            } catch {
                print(error)
            }
        }) {
            RoundedRectangle(cornerRadius: 25)
                .fill(Constants.Colors.greenColor)
                .frame(width: 150, height: 50, alignment: .center)
                .padding(.horizontal)
                .overlay(
                    Text("Sign Out")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
            )
        }
    }
}

struct ProfilePicture: View {
    var body: some View {
        WebImage(url: UserAuthenticator.getUserAuthenticator().getImageURL(),
                 options: [.waitStoreCache, .progressiveLoad, .queryDiskDataSync])
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 175, height: 175)
            .clipShape(Circle())
            .padding()
    }
}

struct UserBio: View {
    var body: some View {
        Group {
            
            
            Text("Michael, 19")
                .font(.title)
            Text("Class of 2023")
            
            HStack {
                Text("About")
                    .bold()
                    .padding(.bottom, 5)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack {
                Text("Hi this is my profile I hope you like what I have to say")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            HStack {
                Text("Major")
                .bold()
                    .padding(.bottom, 5)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack {
                Text("Computer Science")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            
            
        }
    }
}
