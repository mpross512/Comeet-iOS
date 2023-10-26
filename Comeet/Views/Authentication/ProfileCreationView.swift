//
//  ProfileEditView.swift
//  Comeet
//
//  Created by Michael Ross on 10/14/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct ProfileCreationView: View {
    @State private var currentPage: Int = 0
    
    
    var body: some View {
        NavigationStack {
            NavigationLink("Step 1"){
                Text("Let's get your name and age")
                NavigationLink("Step 2") {
                    Text("Let's get your school info")
                    NavigationLink("Step 3") {
                        Text("Upload a picture")
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileCreationView()
}
