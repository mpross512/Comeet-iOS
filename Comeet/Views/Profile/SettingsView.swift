//
//  SettingsView.swift
//  Comeet
//
//  Created by Michael Ross on 12/29/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(Supabase.self) var supabase: Supabase
    @State var confirmDelete = false
    
    
    var body: some View {
        Form {
            Section {
                Button("Sign Out") {
                    Task {
                        do {
                            try await supabase.auth.signOut()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            
            Section {
                Button("Delete Account", role: .destructive) {
                    confirmDelete = true
                }.confirmationDialog("Confirm Delete", isPresented: $confirmDelete) {
                    Button("Yes, Delete", role: .destructive) {
                        Task {
                            do {
                                try await supabase.auth.admin.deleteUser(id: supabase.auth.user().id.uuidString)
                            } catch {
                                print(error)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete your account? This cannot be undone.").font(.title)
                }

            }
        }
    }
}

#Preview {
    SettingsView(confirmDelete: false)
        .environment(Supabase())
}
