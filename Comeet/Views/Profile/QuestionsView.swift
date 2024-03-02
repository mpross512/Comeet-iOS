//
//  QuestionsView.swift
//  Comeet
//
//  Created by Michael Ross on 1/11/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import SwiftUI

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

#Preview {
    QuestionsView(isPresented: .constant(false))
        .environment(UserService())
        .environment(User())
}

struct QuestionView: View {
    @Environment(UserService.self) var userService: UserService
    @Environment(User.self) var currentUser: User
    @Binding var question: Double
    @Binding var isPresented: Bool
    @State var importance: Double = 3
    
    var questionSet = Constants.SetupQuestions.questions
    
    var body: some View {
        VStack {
            Text(questionSet[Int(question)].question).font(.headline)
            
            List {
                Section {
                    ForEach(questionSet[Int(question)].options, id: \.self) { option in
                        Button {
                            DispatchQueue.main.async {
                                if let index = currentUser.attributes.firstIndex(where: {$0.name == questionSet[Int(question)].category}) {
                                    currentUser.attributes[index] = Attribute(
                                        name: questionSet[Int(question)].category,
                                        importance: Int(importance),
                                        value: option)
                                } else {
                                    currentUser.attributes.append(
                                        Attribute(
                                            name: questionSet[Int(question)].category,
                                            importance: Int(importance),
                                            value: option)
                                    )
                                }
                            }
                            if(Int(question) < questionSet.count - 1) {
                                question = question + 1
                            } else {
                                isPresented = false
                                do {
//                                    try Firestore.firestore().collection("Users").document(userService.user.id.uuidString).setData(from: userService.user)
                                } catch let error {
                                    print(error)
                                }
                            }
                        } label: {
                            Text(option)
                        }
                    }
                }
                
                Section {
                    Text("How imortant is it that your partner share this value?")
                    Slider(value: $importance, in: 1...5, step: 1)
                    HStack {
                        Text("Not Important")
                        Spacer()
                        Text("Very Important")
                    }
                }
                
                Button {
                    if(Int(question) < questionSet.count - 1) {
                        question = question + 1
                    } else {
                        isPresented = false
                        do {
//                            try Firestore.firestore().collection("Users").document(userService.user.id.uuidString).setData(from: userService.user)
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
