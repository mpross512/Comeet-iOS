//
//  SignUpView.swift
//  Comeet
//
//  Created by Michael Ross on 7/11/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {

    @State var email: String = ""
    @State var password: String = ""
    @State var passwordConfirm: String = ""
    @State var errorText: String = "Error"
    @State var showErrorText: Bool = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(
                colors: [Constants.Colors.orangeColor, Constants.Colors.orangeColor, Constants.Colors.yellowOrangeColor]),
            startPoint: .leading, endPoint: .trailing)
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            VStack {
                Text("Let's Get You Started")
                    .font(.custom("Futura", size: 40))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                Text(errorText)
                    .foregroundColor(.white)
                    .opacity(showErrorText ? 1 : 0)
                
                TextField("Enter your NetID", text: $email)
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
                
                SecureField("Create a Password", text: $password)
                .foregroundColor(.black)
                .padding(.leading)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25).fill(Color.white)
                )
                    .padding(.horizontal)
                
                SecureField("Confirm Password", text: $passwordConfirm)
                .foregroundColor(.black)
                .padding(.leading)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 25).fill(Color.white)
                )
                    .padding(.horizontal)
                
                
                Button(action: {
                    if(password == passwordConfirm) {
                        Auth.auth().signIn(withEmail: "\(self.email)@utdallas.edu", password: self.password) { authResult, error in
                            if let e = error {
                                self.showErrorText = true
                                self.errorText = e.localizedDescription
                            }
                        }
                    }
                    else {
                        self.showErrorText = true
                        self.errorText = "Passwords do not match"
                    }
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
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
