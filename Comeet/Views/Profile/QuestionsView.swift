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
    @State private var saving = false
    @State private var saveError: String?
    
    var questionSet = Constants.SetupQuestions.questions
    
    var body: some View {
        VStack {
            Text(questionSet[Int(question)].question).font(.headline)
            
            List {
                Section {
                    ForEach(questionSet[Int(question)].options, id: \.self) { option in
                        Button {
                            Task {
                                saving = true
                                defer { saving = false }
                                var attributes = currentUser.attributes
                                let answer = Attribute(name: questionSet[Int(question)].category, importance: Int(importance), value: option)
                                if let index = attributes.firstIndex(where: { $0.name == answer.name }) {
                                    attributes[index] = answer
                                } else { attributes.append(answer) }
                                do {
                                    try await userService.saveAttributes(attributes)
                                    currentUser.attributes = attributes
                                    advance()
                                } catch { SessionStore.shared.handle(error); saveError = error.localizedDescription }
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
                    advance()
                } label: {
                    if(Int(question) != questionSet.count - 1) {
                        Text("Skip")
                    } else {
                        Text("Finish")
                    }
                }
            }
        }.disabled(saving)
        .alert("Could not save answer", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
    }
    private func advance() {
        if Int(question) < questionSet.count - 1 { question += 1 } else { isPresented = false }
    }
}
