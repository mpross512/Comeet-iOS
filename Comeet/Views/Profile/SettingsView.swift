//
//  SettingsView.swift
//  Comeet
//
//  Created by Michael Ross on 12/29/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    
    var body: some View {
        Form {
            Section {
                Button {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print(error)
                    }
                } label: {
                    Text("Sign Out")
                }

            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
