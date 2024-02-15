//
//  ProfileEditView.swift
//  Comeet
//
//  Created by Michael Ross on 11/22/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileEditView: View {
    
    
    @State var user = User()
    @State var firstName: String
    @State var lastName: String
    @State var birthdate: Date
    @State var major: String = ""
    @State var year: String = ""
    @State var bio: String = ""
    @State var showingAlert: Bool = false
    @State private var isShowPhotoLibrary = false
    @State private var imageAlertShown = false
    @State private var isShowingQuestionsView = false

    
    init(user: User) {
        _user = State(initialValue: user)
        _firstName = State(initialValue: user.firstName)
        _lastName = State(initialValue: user.lastName)
        _birthdate = State(initialValue: user.birthdate)
        _year = State(initialValue: String(user.graduationYear))
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
            } header: {
                Text("SCHOOL")
            }
            
            Section {
                TextField("", text: $user.bio, axis: .vertical)
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
                    showingAlert = true
                    user.firstName = firstName
                    user.lastName = lastName
                    user.birthdate = birthdate
                    user.graduationYear = Int(year) ?? 0
//                    do {
//                        try Firestore.firestore().collection("Users").document(user.id.uuidString).setData(from: user)
//                    } catch let error {
//                        print(error)
//                    }
                } label: {
                    Text("Save Changes")
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text("Changes Saved"),
                          message: Text("You may need to reload the app for your changes to take effect"))
                }
            } header: {
                EmptyView()
            }
        }.sheet(isPresented: $isShowPhotoLibrary) {
            ImagePicker(isShown: $isShowPhotoLibrary, alertShown: $imageAlertShown)
        }.sheet(isPresented: $isShowingQuestionsView){
            QuestionsView(currentQuestion: 0, isPresented: $isShowingQuestionsView)
        }.alert(isPresented: $imageAlertShown) {
            Alert(title: Text("Image Saved"),
            message: Text("You may need to close the app for the new image to take effect"))
        }.scrollDismissesKeyboard(.automatic)
    }
}

#Preview {
    ProfileEditView(user: User())
}
