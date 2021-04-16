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
    
    @State var isInEditMode: Bool = false
    @State var profilePicURL: URL?
    @State var imageCache = SDImageCache.shared
    
    let userHandler = UserHandler.getUserHandler()
        
    init() {
        userHandler.refresh()
    }
    
    var body: some View {
        
        NavigationView {
        
            VStack {
                NavigationLink(destination: EditView(), isActive: $isInEditMode) { EmptyView() }
                
                ScrollView {
                
                    ProfilePicture(width: 175, height: 175)
                        .padding()
                    
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
                UserHandler.getUserHandler().refresh()
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
    
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        WebImage(url: UserHandler.getUserHandler().getImageURL())
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
            
            
            
            Text("\(UserHandler.getUserHandler().user.getFirstName()), \(UserHandler.getUserHandler().user.getAge())")
                .font(.title)
            Text("Class of \(String(UserHandler.getUserHandler().user.getYear()))")
            
            HStack {
                Text("About")
                    .bold()
                    .padding(.bottom, 5)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack {
                Text("\(UserHandler.getUserHandler().user.getBio())")
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
                Text("\(UserHandler.getUserHandler().user.getMajor())")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            
            
        }
    }
}
