//
//  UserService.swift
//  Comeet
//
//  Created by Michael Ross on 11/14/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseFirestore

@MainActor
class UserService: ObservableObject {
    
    @Published var user: User
    @Published var matches: [User]
    @Published var isLoading: Bool
    
    init() {
        user = User()
        matches = []
        isLoading = false
    }
    
    func getUser(uid: String) async {
        print("DEBUG: Get User called")
        isLoading = true
        do {
            let document = try await Firestore.firestore().collection("Users").document(uid).getDocument()
            let decoder = JSONDecoder()
            let data = document.data()
                //Serialize the Dictionary into a JSON Data representation, then decode it using the Decoder().
                if let data = try? JSONSerialization.data(withJSONObject: data!, options: []) {
                    do {
                        self.user = try decoder.decode(User.self, from: data)
                        print("DEBUG: User initialized")
                        await getMatches()
                    } catch {
                        print(error)
                    }
                }
        }
        catch {
            print(error)
        }
    }
    
    func getMatches() async {
        print("DEBUG: Get Matches called")
        print("DEBUG: user.matches: ", user.matches)
        for uid in user.matches {
            do {
                let document = try await Firestore.firestore().collection("Users").document(uid).getDocument()
                let decoder = JSONDecoder()
                let data = document.data()
                //Serialize the Dictionary into a JSON Data representation, then decode it using the Decoder().
                if let data = try? JSONSerialization.data(withJSONObject: data!, options: []) {
                    do {
                        let match = try decoder.decode(User.self, from: data)
                        match.pictureRef = try await Constants.Database.profilePicsRef.child("\(uid).jpeg").downloadURL()
                        matches.append(match)
                        print("DEBUG: Matche loaded: \(match)")
                    } catch {
                        print(error)
                    }
                }
            }
            catch {
                print(error)
            }
        }
        isLoading = false
    }
}
