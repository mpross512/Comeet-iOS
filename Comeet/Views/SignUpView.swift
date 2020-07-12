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
    let yellowOrangeColor = Color(red: 0.95, green: 0.61, blue: 0.07, opacity: 1.00)
    let orangeColor = Color(red: 0.90, green: 0.49, blue: 0.13, opacity: 1.00)
    
    @State var email: String = ""
    @State var password: String = ""
    @State var errorText: String = "Error"
    @State var showErrorText: Bool = false
    
    var body: some View {
        ZStack {
            
            LinearGradient(gradient: Gradient(
            colors: [orangeColor, orangeColor, yellowOrangeColor]),
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
                
                TextField("Email", text: $email)
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
                    Auth.auth().signIn(withEmail: self.email, password: self.password) { authResult, error in
                        if let e = error {
                            self.showErrorText = true
                            self.errorText = e.localizedDescription
                        }
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
