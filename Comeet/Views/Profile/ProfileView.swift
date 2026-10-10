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

//struct ProfileView_Previews: PreviewProvider {
    //@Namespace var ns
    //static var previews: some View {
        //ProfileView(namespace: ns).environment(Supabase.shared).environment(PreviewModels.previewUser)
    //}
//}

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
    @Environment(NamespaceController.self) var namespace
    
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
            .indicator(.init(content: { isAnimating, progress in
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
                    .redacted(reason: .placeholder)
            }))
            .aspectRatio(contentMode: .fill)
            .matchedGeometryEffect(id: "MatchImage", in: namespace.matchCard)
            .transition(.offset())
            .transition(.scale)
            .frame(width: width, height: height)
            .clipShape(Circle())
            
    }
}

struct UserBio: View {
    @Environment(NamespaceController.self) var namespace
    
    @State var user: any Person = User()
    
    var body: some View {
        VStack {
            
            Text("\(user.fullName), \(user.age)")
                .font(.title)
                .matchedGeometryEffect(id: "MatchName", in: namespace.matchCard)
            Text("Class of \(String(user.graduationYear))")
                .matchedGeometryEffect(id: "MatchYear", in: namespace.matchCard)
            
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
