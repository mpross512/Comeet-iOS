//
//  MessageView.swift
//  Comeet
//
//  Created by Michael Ross on 10/11/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import SwiftUI
import FirebaseFunctions

struct MessageView: View {
    
    @State var user: User
    lazy var functions = Functions.functions()
    
    var body: some View {

            VStack {
                ScrollView {
                    Text("You and \(user.name["first"] ?? "") both like each other!").italic().font(.caption).foregroundColor(.gray)
                    Button {
                        functions.httpsCallable("addMessage").call(["text": "this is a test"]) { result, error in
                          if let error = error as NSError? {
                            if error.domain == FunctionsErrorDomain {
                              let code = FunctionsErrorCode(rawValue: error.code)
                              let message = error.localizedDescription
                              let details = error.userInfo[FunctionsErrorDetailsKey]
                            }
                            // ...
                          }
                          if let data = result?.data as? [String: Any], let text = data["text"] as? String {
                            self.resultField.text = text
                          }
                        }
                    } label: {
                        Text("Test function")
                    }

                }
                
                
            }.toolbar{
                ToolbarItem(placement: .principal) {
                    Text("\(user.name["first"] ?? "") \(user.name["last"] ?? "")").bold()
                }
            }
        
        
        
    }
}

struct IndividualMessage: View {
    var body: some View {
        Text("Individual Message")
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(user: User())
    }
}
