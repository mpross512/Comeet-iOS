//
//  ProfileCreationView.swift
//  Comeet
//
//  Created by Michael Ross on 11/22/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct ProfileCreationView: View {
    
    @State var newUser = User()
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var birthdate: Date = Date()
    @State var major: String = ""
    @State var year: String = ""
    @State var bio: String = ""
    @State var showingAlert: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("PERSONAL")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                DatePicker("Birthdate", selection: $birthdate, displayedComponents: .date)
            }
            
            Section(header: Text("SCHOOL")) {
                Picker("Major", selection: $major) {
                    ForEach(Constants.Values.degrees, id: \.self) { major in
                        Text(major)
                    }
                }
                TextField("Graduation Year", text: $year)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("BIO")) {
                TextEditor(text: $bio)
            }

            Section {
                Button {
                    showingAlert = true
                    //Implement save function
                } label: {
                    Text("Save Changes")
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text("Changes Saved"))
                }

            }
        }
    }
}

struct ProfileCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCreationView()
    }
}
