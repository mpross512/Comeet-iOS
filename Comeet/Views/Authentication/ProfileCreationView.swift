//
//  ProfileCreationView.swift
//  Comeet
//
//  Created by Michael Ross on 10/14/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import ComeetData
import SDWebImageSwiftUI

struct ProfileCreationView: View {
    @State private var currentPage: Int = 0
    @State var newUser: User = User()
    
    var body: some View {
        NavigationStack {
            ProfileCreationStep1(user: newUser)
        }
    }
}

struct ProfileCreationStep1: View {
    @Bindable var user: User
    
    var body: some View {
        VStack {
            Text("Let's get your info!").font(.title).padding()
            Form {
                Section() {
                    TextField("First Name", text: $user.firstName)
                    TextField("Last Name", text: $user.lastName)
                    DatePicker("Birthdate", selection: $user.birthdate, displayedComponents: .date)
                }
            }.padding()
            NavigationLink {
                ProfileCreationStep2(user: user)
            } label: {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Constants.Colors.greenColor)
                    .frame(width: 150, height: 50, alignment: .center)
                    .padding(.horizontal)
                    .overlay(
                        Text("Next")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

struct ProfileCreationStep2: View {
    @Bindable var user: User
    @State var year: String = ""
    
    var body: some View {
        VStack {
            Text("Just a few more things!").font(.title).padding()
            Form {
                Section() {
                    Picker("Major", selection: $user.major) {
                        ForEach(Constants.Values.degrees, id: \.self) { major in
                            Text(major)
                        }
                    }
                    HStack {
                        Text("Graduation Year")
                        Spacer()
                        TextField("", text: $year)
                            .keyboardType(.decimalPad)
                    }
                }
            }.padding()
            NavigationLink {
                ProfileCreationStep3(user: user)
                    .onAppear { user.graduationYear = Int(year) ?? 0 }
            } label: {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Constants.Colors.greenColor)
                    .frame(width: 150, height: 50, alignment: .center)
                    .padding(.horizontal)
                    .overlay(Text("Next").fontWeight(.bold).foregroundColor(.white))
            }
        }
    }
}

struct ProfileCreationStep3: View {
    var user: User
    @State private var saveError: String?
    @State private var saving = false
    @State private var isShowPhotoLibrary = false
    @State private var imageAlertShown = false
    
    var body: some View {
        VStack {
            Text("Picture time!").font(.title).padding()
            Button(action: {
                self.isShowPhotoLibrary = true
            }) {
                HStack {
                    Spacer()
                    
                    ZStack {
                        WebImage(url: URL(string: "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png")!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 125, height: 125)
                            .clipShape(Circle())
                        
//                        Image(systemName: "pencil.circle.fill").font(.system(size: 40))
//                            .foregroundColor(Constants.Colors.greenColor)
//                            .offset(x: 50, y: -50)
                    }
                    
                    Spacer()
                }
            }
            Button {
                Task {
                    saving = true
                    defer { saving = false }
                    do {
                        try await SessionStore.shared.saveProfile(ProfileFields(
                            firstName: user.firstName, lastName: user.lastName,
                            birthdate: WireDates.birthday(user.birthdate), graduationYear: user.graduationYear,
                            major: user.major, bio: user.bio))
                    } catch { SessionStore.shared.handle(error); saveError = error.localizedDescription }
                }
            } label: {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Constants.Colors.greenColor)
                    .frame(width: 150, height: 50, alignment: .center)
                    .padding(.horizontal)
                    .overlay(
                        Text("Finish")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
        }.disabled(saving)
        .alert("Could not save profile", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
        .sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(isShown: $isShowPhotoLibrary, alertShown: $imageAlertShown)
        }
    }
}

#Preview {
    ProfileCreationView()
}
