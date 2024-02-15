//
//  ProfileView.swift
//  Comeet
//
//  Created by Michael Ross on 7/12/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileView: View {
    
    @Environment(User.self) var currentUser: User
    
    @State var isInEditMode: Bool = false
    @State var profilePicURL: URL?
    @State var imageCache = SDImageCache.shared
    @State var settingsPageShown: Bool = false
    
    var user: User = User()
    
    var body: some View {
        
        NavigationStack {
        
            VStack {
                ScrollView {
                
                    ProfilePicture(userID: currentUser.id, width: 175, height: 175)
                        .padding()
                    
                    UserBio(user: currentUser)
                    
                    UserInterests(attributes: currentUser.attributes)
                    
                    Button {
                        self.isInEditMode.toggle();
                    } label: {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Constants.Colors.greenColor)
                            .frame(width: 150, height: 50, alignment: .center)
                            .padding(.horizontal)
                            .overlay(
                                Text("Edit Profile")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                        )
                    }
                }
                    
            }
            .navigationDestination(isPresented: $settingsPageShown) {
                SettingsView()
            }
            .navigationDestination(isPresented: $isInEditMode) {
                EditView(user: currentUser)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settingsPageShown.toggle()
                        print("DEBUG: settingsPageShown: \(settingsPageShown)")
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title)
                            .accentColor(Constants.Colors.greenColor)
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

struct SignOutButton: View {
    @Environment(Supabase.self) var supabase
        
    var body: some View {
        Button {
            Task {
                do {
                    try await supabase.auth.signOut()
                } catch {
                    print(error)
                }
            }
        } label: {
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
    let profileURL: URL
    let width: CGFloat
    let height: CGFloat
    
    init(userID: UUID, width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        
        do {
            self.profileURL = try Supabase.shared.storage
                .from("profile-pictures")
                .getPublicURL(path: "\(userID.uuidString.lowercased()).jpeg")
        } catch {
            print("ERROR: \(error)")
            self.profileURL = URL(string: "")!
        }
    }
    
    var body: some View {
        WebImage(url: profileURL)
            .resizable()
            .indicator(.activity)
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipShape(Circle())
    }
}

struct UserBio: View {
    
    @State var user: any Person = User()
    
    var body: some View {
        Group {
            
            Text("\(user.fullName), \(user.age)")
                .font(.title)
            Text("Class of \(String(user.graduationYear))")
            
            HStack {
                Text("About")
                    .bold()
                    .padding(.bottom, 5)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            HStack {
                Text("\(user.bio)")
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
                Text("\(user.major)")
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            
            
        }
    }
}
