//
//  SignUpView.swift
//  Comeet
//
//  Created by Michael Ross on 7/11/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct SignUpView: View {

    @State var netID: String = ""
    @State var password: String = ""
    @State var errorText: String = "Error"
    @State var showErrorText: Bool = false
    @State var createAccount: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(
                    colors: [Constants.Colors.orangeColor, Constants.Colors.yellowOrangeColor]),
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Let's Get You Started")
                        .font(.custom("Futura", size: 40))
                        .foregroundColor(.white)
                        .padding(.bottom, 50)
                    
                    Text(errorText)
                        .foregroundColor(.white)
                        .opacity(showErrorText ? 1 : 0)
                    
                    TextField("Enter your NetID", text: $netID)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .foregroundColor(.black)
                        .padding(.leading)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25).fill(Color.white)
                        )
                        .padding(.horizontal)
                    
                    SecureField("Create a Password", text: $password)
                        .foregroundColor(.black)
                        .padding(.leading)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25).fill(Color.white)
                        )
                        .padding(.horizontal)
                    
                    Button(action: {
                        #if DEBUG
                        Task {
                            do {
                                try await Supabase.shared.auth.signUp(
                                    email: "\(self.netID)",
                                    password: self.password
                                )
                                createAccount = true
                            } catch {
                                print(error)
                                self.errorText = error.localizedDescription
                                self.showErrorText = true
                            }
                        }
                        #else
                        if(self.netID.count != 9) {
                            self.showErrorText = true
                            self.errorText = "Please enter a valid 9 character NetID"
                        }
                        else {
                            self.showErrorText = false
                            Task {
                                try await Supabase.shared.auth.signUp(
                                    email: "\(self.netID)@utdallas.edu",
                                    password: self.password
                                )
                                createAccount = true
                            }
                        }
                        #endif
                    }) {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .frame(height: 50, alignment: .center)
                            .padding()
                            .overlay(
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.15, green: 0.68, blue: 0.38, opacity: 1.00))
                            )
                            .padding(.top, 20)
                    }
                }
            }.navigationDestination(isPresented: $createAccount) {
                ProfileCreationView().navigationBarBackButtonHidden()
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
