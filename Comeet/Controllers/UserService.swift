//
//  UserService.swift
//  Comeet
//
//  Created by Michael Ross on 11/14/22.
//  Copyright © 2022 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

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
        //isLoading = true
        do {
            self.user = try await Firestore.firestore().collection("Users").document(uid).getDocument(as: User.self)
            print("DEBUG: User Data Loaded")
            user.pictureRef = try await Constants.Database.profilePicsRef.child("\(uid).jpeg").downloadURL()
            print("DEBUG: Profile Pic Ref Loaded")
            print("DEBUG: \(String(describing: user.pictureRef))")
            await getMatches()
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
                var match = try await Firestore.firestore().collection("Users").document(uid).getDocument(as: User.self)
                //Serialize the Dictionary into a JSON Data representation, then decode it using the Decoder().
                match.pictureRef = try await Constants.Database.profilePicsRef.child("\(uid).jpeg").downloadURL()
                matches.append(match)
            }
            catch {
                print(error)
            }
        }
        isLoading = false
    }
}
