//
//  ProfileCreationView.swift
//  Comeet
//
//  Created by Michael Ross on 11/22/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import SwiftUIBackports
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ProfileCreationView: View {
    
    @State var user = User()
    @State var firstName: String
    @State var lastName: String
    @State var birthdate: Date
    @State var major: String = ""
    @State var year: String = ""
    @State var bio: String = ""
    @State var showingAlert: Bool = false
    
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
                TextField("Graduation Year", text: $year)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("BIO")) {
                TextEditor(text: $user.bio)
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
        }.backport.scrollDismissesKeyboard(.immediately)
    }
}

struct ProfileCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCreationView(user: User())
    }
}
