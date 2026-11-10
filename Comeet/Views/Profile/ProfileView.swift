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
    @State var settingsPageShown: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                // Laid out like a match's profile so people see themselves the way others do.
                VStack(spacing: 16) {
                    MatchCardView(match: currentUser, cornerRadius: 0)
                        .overlay(alignment: .top) {
                            // Keeps the settings button readable over light photos.
                            LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 120)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        .accessibilityAddTraits(.isHeader)

                    UserBio(user: currentUser, showsHeader: false)

                    UserInterests(attributes: currentUser.attributes)

                    VStack(spacing: 8) {
                        Button {
                            isInEditMode = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 34)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(Constants.Colors.greenColor)

                        Text("This is how your profile appears to your matches.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationDestination(isPresented: $settingsPageShown) {
                SettingsView()
            }
            .navigationDestination(isPresented: $isInEditMode) {
                EditView(user: currentUser)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        settingsPageShown = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tint(Constants.Colors.greenColor)
                }
            }
        }
    }
}

//struct ProfileView_Previews: PreviewProvider {
    //@Namespace var ns
    //static var previews: some View {
        //ProfileView(namespace: ns).environment(SessionStore.shared).environment(PreviewModels.previewUser)
    //}
//}

struct SignOutButton: View {
    @Environment(SessionStore.self) var session
        
    var body: some View {
        Button {
            Task {
                do {
                    try await session.signOut()
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
    
    @Environment(SessionStore.self) private var session
    let userID: UUID
    var profileURL: URL { APIConfiguration.photoURL(userID: userID) }
    var photoRefreshID: UUID? { userID == session.currentUser.id ? session.profilePhotoRevision : nil }
    let width: CGFloat
    let height: CGFloat
    
    init(userID: UUID, width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
        
        self.userID = userID
    }
    
    var body: some View {
        WebImage(url: profileURL)
            .resizable()
            // Shown while loading and when there is no photo or it fails to load (photos are optional).
            .placeholder {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(width: width, height: height)
            }
            .id(photoRefreshID)
            .aspectRatio(contentMode: .fill)
            .transition(.offset())
            .transition(.scale)
            .frame(width: width, height: height)
            .clipShape(Circle())
            
    }
}

struct UserBio: View {

    let user: any Person
    /// Off when the screen already shows the name, class year and major, as the match profile's photo card does.
    var showsHeader = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showsHeader {
                VStack(spacing: 4) {
                    Text("\(user.fullName), \(user.age)")
                        .font(.title)
                        .accessibilityAddTraits(.isHeader)
                    Text("Class of \(String(user.graduationYear))")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }

            if !user.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                section("About", text: user.bio)
            }
            if showsHeader, !user.major.isEmpty {
                section("Major", text: user.major)
            }
        }
        .padding(.horizontal)
    }

    private func section(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text(text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
