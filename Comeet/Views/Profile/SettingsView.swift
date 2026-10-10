//
//  SettingsView.swift
//  Comeet
//
//  Created by Michael Ross on 12/29/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) var session
    @State var confirmDelete = false
    
    
    var body: some View {
        Form {
            Section {
                Button("Sign Out") {
                    Task {
                        do {
                            try await session.signOut()
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
                                try await session.deleteAccount()
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
        .environment(SessionStore.shared)
}
