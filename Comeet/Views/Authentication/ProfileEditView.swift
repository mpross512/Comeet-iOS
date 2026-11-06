//
//  ProfileEditView.swift
//  Comeet
//
//  Created by Michael Ross on 11/22/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import ComeetData

struct ProfileEditView: View {
    
    
    @Environment(SessionStore.self) private var session
    let user: User
    @State var firstName: String
    @State var lastName: String
    @State var birthdate: Date
    @State var major: String = ""
    @State var year: String = ""
    @State var bio: String = ""
    @State private var saving = false
    @State private var saveError: String?
    @State var showingAlert: Bool = false
    @State private var isShowPhotoLibrary = false
    @State private var imageAlertShown = false
    @State private var isShowingQuestionsView = false

    
    init(user: User) {
        self.user = user
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _birthdate = State(initialValue: user.birthdate)
        _year = State(initialValue: String(user.graduationYear))
        _major = State(initialValue: user.major)
        _bio = State(initialValue: user.bio)
    }
    
    var body: some View {
        Form {
            Section {
                Button {
                    self.isShowPhotoLibrary = true
                } label: {
                    HStack {
                        Spacer()
                        ZStack {
                            ProfilePicture(userID: user.id, width: 125, height: 125)
                            Image(systemName: "pencil.circle.fill").font(.system(size: 40))
                                .foregroundColor(Constants.Colors.greenColor)
                                .offset(x: 50, y: -50)
                        }
                        Spacer()
                    }
                }
            } header: {
                Text("EDIT PROFILE PICTURE")
            }
            
            Section {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
            } header: {
                Text("PERSONAL")
            }
            
            Section {
                Picker("Major", selection: $major) {
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
            } header: {
                Text("SCHOOL")
            }
            
            Section {
                TextField("", text: $bio, axis: .vertical)
                    .frame(minHeight: 40, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5, reservesSpace: true)
            } header: {
                Text("BIO")
            }
            
            Section {
                Button {
                    isShowingQuestionsView = true
                } label: {
                    Text("Personal Attributes")
                }
            } header: {
                Text("MORE")
            }
            
            Section {
                Button {
                    Task {
                        saving = true
                        defer { saving = false }
                        do {
                            try await session.saveProfile(ProfileFields(
                                firstName: firstName, lastName: lastName,
                                birthdate: WireDates.birthday(birthdate),
                                graduationYear: Int(year) ?? 0, major: major, bio: bio))
                            showingAlert = true
                        } catch { session.handle(error); saveError = error.localizedDescription }
                    }
                } label: {
                    Text("Save Changes")
                }.disabled(saving).alert(isPresented: $showingAlert) {
                    Alert(title: Text("Changes Saved"))
                }
            } header: {
                EmptyView()
            }
        }.sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(isShown: $isShowPhotoLibrary, alertShown: $imageAlertShown)
        }.sheet(isPresented: $isShowingQuestionsView){
            QuestionsView(currentQuestion: 0, isPresented: $isShowingQuestionsView)
        }.alert(isPresented: $imageAlertShown) {
            Alert(title: Text("Image Saved"))
        }.alert("Could not save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
        .scrollDismissesKeyboard(.automatic)
    }
}

#Preview {
    ProfileEditView(user: User())
}
