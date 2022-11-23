//
//  ContentView.swift
//  Comeet
//
//  Created by Michael Ross on 7/7/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct InitialView: View {
    
    @State var isSignInSheet: Bool = false
    @State var isSignUpSheet: Bool = false
    

    
    var body: some View {
        ZStack{
            
            
            LinearGradient(gradient: Gradient(
                colors: [Constants.Colors.orangeColor, Constants.Colors.orangeColor, Constants.Colors.yellowOrangeColor]),
                startPoint: .leading, endPoint: .trailing)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            
            /*
            Color(.white)
                .edgesIgnoringSafeArea(.all)
            */
            
            VStack{
                Text("👌 Comeet")
                    .foregroundColor(.white)
                    .font(.custom("Futura", size: 50))
                    .padding(.bottom, 200)
                
                Button(action: {
                    self.isSignUpSheet.toggle()
                }) {
                    AccountButton(text: "Create Account")
                }.sheet(isPresented: $isSignUpSheet) {
                    SignUpView()
                }
                
                Button(action: {
                    self.isSignInSheet.toggle()
                }) {
                    AccountButton(text: "Sign In")
                }.sheet(isPresented: $isSignInSheet) {
                    SignInView()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        InitialView()
    }
}

struct AccountButton: View {
    
    var text: String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.white)
            //.stroke(Constants.Colors.orangeColor, lineWidth: 3)
            .frame(height: 50, alignment: .center)
            .padding(.horizontal)
            //.padding(.bottom)
            .overlay(
                Text(text)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.15, green: 0.68, blue: 0.38, opacity: 1.00))
            )
    }
}
