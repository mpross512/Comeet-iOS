//
//  QuestionsView.swift
//  Comeet
//
//  Created by Michael Ross on 1/11/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

import FirebaseFirestore

struct QuestionsView: View {
    
    @State var currentQuestion: Double = 0
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            
            ProgressView(value: currentQuestion + 1, total: Double(Constants.SetupQuestions.questions.count))
            
            QuestionView(question: $currentQuestion, isPresented: $isPresented)
            
            
        }.accentColor(Constants.Colors.orangeColor)
    }
}

struct QuestionsView_Previews: PreviewProvider {
    static var previews: some View {
        //QuestionsView(isPresented: false)
        Text("No Preview")
    }
}

struct QuestionView: View {
    
    @Binding var question: Double
    
    @Binding var isPresented: Bool
    
    @EnvironmentObject var userService: UserService
    
    var questionSet = Constants.SetupQuestions.questions
    
    var body: some View {
        VStack {
            Text(questionSet[Int(question)].question).font(.headline)
            
            List {
                Section {
                    ForEach(questionSet[Int(question)].options, id: \.self) { option in
                        Button {
                            userService.user.attributes[questionSet[Int(question)].category] =
                            Attribute(
                                name: questionSet[Int(question)].category,
                                importance: 5,
                                value: option)
                            if(Int(question) < questionSet.count - 1) {
                                question = question + 1
                            } else {
                                isPresented = false
                                do {
                                    try Firestore.firestore().collection("Users").document(userService.user.id!).setData(from: userService.user)
                                } catch let error {
                                    print(error)
                                }
                            }
                        } label: {
                            Text(option)
                        }
                    }
                }
                
                Button {
                    userService.user.attributes[questionSet[Int(question)].category] =
                        Attribute(
                            name: questionSet[Int(question)].category,
                            importance: 5,
                            value: "")
                    if(Int(question) < questionSet.count - 1) {
                        question = question + 1
                    } else {
                        isPresented = false
                        do {
                            try Firestore.firestore().collection("Users").document(userService.user.id!).setData(from: userService.user)
                        } catch let error {
                            print(error)
                        }
                    }
                } label: {
                    if(Int(question) != questionSet.count - 1) {
                        Text("Skip")
                    } else {
                        Text("Finish")
                    }
                }
            }
        }
    }
}
