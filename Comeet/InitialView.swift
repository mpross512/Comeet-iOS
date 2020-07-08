//
//  ContentView.swift
//  Comeet
//
//  Created by Michael Ross on 7/7/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

struct InitialView: View {
    
    let yellowOrangeColor = Color(red: 0.95, green: 0.61, blue: 0.07, opacity: 1.00)
    let greenColor = Color(red: 0.15, green: 0.68, blue: 0.38, opacity: 1.00)
    let orangeColor = Color(red: 0.90, green: 0.49, blue: 0.13, opacity: 1.00)
    
    var body: some View {
        ZStack{
            
            LinearGradient(gradient: Gradient(colors: [orangeColor, orangeColor, yellowOrangeColor]), startPoint: .leading, endPoint: .trailing)
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            VStack{
                //Text("Welcome To")
                  //  .foregroundColor(.white)
                    //.font(.title)
                
                Text("👌 Comeet")
                    .foregroundColor(.white)
                    .font(.custom("Futura", size: 50))
                    .padding(.bottom, 200)
                
                
                AccountButton(text: "Create Account")
                AccountButton(text: "Sign In")
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
