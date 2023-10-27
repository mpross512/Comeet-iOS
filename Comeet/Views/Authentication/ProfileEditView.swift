//
//  ProfileEditView.swift
//  Comeet
//
//  Created by Michael Ross on 11/22/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
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
        print("Edit view initialized with user")
        print(user)
        _user = State(initialValue: user)
        _firstName = State(initialValue: user.name["first"] ?? "")
        _lastName = State(initialValue: user.name["last"] ?? "")
        print("User object first name: ", user.name["first"] ?? "")
        //print("First name: ", self.firstName)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        _birthdate = State(initialValue: dateFormatter.date(from: user.birthdate) ?? Date())
        _year = State(initialValue: String(user.year))
    }
    
    var body: some View {
        Form {
            
            Section (header: Text("EDIT PROFILE PICTURE")) {
                Button(action: {
                    self.isShowPhotoLibrary = true
                }) {
                    HStack {
                        Spacer()
                        
                        ZStack {
                            WebImage(url: user.pictureRef)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 125, height: 125)
                                .clipShape(Circle())
                            
                            Image(systemName: "pencil.circle.fill").font(.system(size: 40))
                                .foregroundColor(Constants.Colors.greenColor)
                                .offset(x: 50, y: -50)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("PERSONAL")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
            }
            
            Section(header: Text("SCHOOL")) {
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
            
            Section(header: Text("BIO")) {
                TextField("", text: $user.bio, axis: .vertical)
                    .frame(minHeight: 40, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(5, reservesSpace: true)
            }
            
            Section(header: Text("MORE")) {
                Button {
                    isShowingQuestionsView = true
                } label: {
                    Text("Personal Attributes")
                }
            }

            Section {
                Button {
                    showingAlert = true
                    user.name["first"] = firstName
                    user.name["last"] = lastName
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let newDate = dateFormatter.string(from: birthdate)
                    user.birthdate = newDate
                    user.year = Int(year) ?? 0
                    do {
                        try Firestore.firestore().collection("Users").document(user.id!).setData(from: user)
                    } catch let error {
                        print(error)
                    }
                } label: {
                    Text("Save Changes")
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text("Changes Saved"),
                          message: Text("You may need to reload the app for your changes to take effect"))
                }

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
