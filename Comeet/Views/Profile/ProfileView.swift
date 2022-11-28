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
import FirebaseFirestore
import SDWebImageSwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var userService: UserService
    
    @State var isInEditMode: Bool = false
    @State var profilePicURL: URL?
    @State var imageCache = SDImageCache.shared
    
    var user: User = User()
        
    init() {
    }
    
    var body: some View {
        
        NavigationView {
        
            VStack {
                NavigationLink(destination: EditView(user: userService.user), isActive: $isInEditMode) { EmptyView() }
                
                ScrollView {
                
                    ProfilePicture(profileURL: userService.user.pictureRef, width: 175, height: 175)
                        .padding()
                    
                    UserBio(user: userService.user)
                    
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
    
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        Button(action: {
            do {
                try Auth.auth().signOut()
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
    
    var profileURL: URL?
    
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        WebImage(url: profileURL ?? UserHandler.getUserHandler().getImageURL())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipShape(Circle())
    }
}

struct UserBio: View {
    
    @State var user: User = User()
    
    var body: some View {
        Group {
            
            Text("\(user.name["first"] ?? "") \(user.name["last"] ?? ""), \(user.getAge())")
                .font(.title)
            Text("Class of \(String(user.getYear()))")
            
            HStack {
                Text("About")
                    .bold()
                    .padding(.bottom, 5)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack {
                Text("\(user.getBio())")
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
                Text("\(user.getMajor())")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            
            
        }
    }
}
