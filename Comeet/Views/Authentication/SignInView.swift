//
//  LoginView.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import Supabase

struct SignInView: View {
    @Environment(Supabase.self) var supabase: Supabase
    
    @State var email: String = ""
    @State var password: String = ""
    @State var errorText: String = "Error"
    @State var showErrorText: Bool = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(
                colors: [Constants.Colors.orangeColor, Constants.Colors.orangeColor, Constants.Colors.yellowOrangeColor]),
            startPoint: .leading, endPoint: .trailing)
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            VStack {
                Text("Welcome Back")
                    .font(.custom("Futura", size: 40))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                Text(errorText)
                    .foregroundColor(.white)
                    .opacity(showErrorText ? 1 : 0)
                
                TextField("NetID", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.black)
                    .padding(.leading)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25).fill(Color.white)
                    )
                    .padding(.horizontal)
                
                SecureField("Password", text: $password)
                .foregroundColor(.black)
                .padding(.leading)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25).fill(Color.white)
                )
                    .padding(.horizontal)
                
                
                Button(action: {
                    Task {
                        do {
                            #if DEBUG
                            let response = try await supabase.auth.signIn(
                                email: "\(self.email)",
                                password: "\(self.password)"
                            )
                            #else
                            let response = try await supabase.auth.signIn(
                                email: "\(self.email)@utdallas.edu",
                                password: "\(self.password)"
                            )
                            #endif
                            print("DEBUG: Supabase Auth: \(response)")
                        } catch {
                            print("ERROR: \(error)")
                            errorText = error.localizedDescription
                        }
                    }
                }) {
                    RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(height: 50, alignment: .center)
                    .padding()
                    .overlay(
                        Text("Sign In")
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.15, green: 0.68, blue: 0.38, opacity: 1.00))
                    )
                    .padding(.top, 20)
                }
                
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environment(Supabase())
    }
}
