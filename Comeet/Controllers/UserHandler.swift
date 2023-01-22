//
//  UserAuthenticator.swift
//  Comeet
//
//  Created by Michael Ross on 7/10/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImageSwiftUI

class UserHandler : ObservableObject {
    
    static private var singleton: UserHandler?
    
    @Published private var signedIn: Bool = false
    
    private var uid: String
    
    private var profilePicReference: StorageReference
    private var imageURL: URL?
    
    public var user: User
    
    init(_ signedIn: Bool) {
        self.signedIn = signedIn
        uid = Auth.auth().currentUser?.uid ?? "default"
        profilePicReference = Constants.Database.profilePicsRef.child("\(uid).jpeg")
        user = User()
        print("Init singleton function")
        //refreshUserData()
    }
    
    static func getUserHandler() -> UserHandler {
        
        if singleton == nil {
            singleton = UserHandler(Auth.auth().currentUser != nil)
            print("Singleton function")
            //singleton?.refreshUserData()
        }
        return singleton!
        
    }
    
    func getUser(uid: String) async -> User {
        var u = User()
        
        do {
            let doc = try await Firestore.firestore().collection("Users").document(uid).getDocument(as: User.self)
            
            u = doc
            u.pictureRef = try await Constants.Database.profilePicsRef.child("\(uid).jpeg").downloadURL()
        } catch {
            print(error)
        }
        return u
    }
    
    func refreshUserData() async {
        refresh()
        do {
            self.user = try await Firestore.firestore().collection("Users").document(uid).getDocument(as: User.self)
        } catch {
            print(error)
        }
        
        self.user.id = uid
    }
    
    func refresh() {
        signedIn = Auth.auth().currentUser != nil
        uid = Auth.auth().currentUser?.uid ?? "default"
        profilePicReference = Constants.Database.profilePicsRef.child("\(uid).jpeg")
        profilePicReference.downloadURL { (url, error) in
            if let e = error {
                print(e)
            } else {
                self.imageURL = url!
            }
        }
        
    }
    
    func isSignedIn() -> Bool {
        if signedIn {
            
        }
        return signedIn
    }
    
    func getImageURL() -> URL? {
        if(imageURL == nil) {
            profilePicReference = Constants.Database.profilePicsRef.child("\(uid).jpeg")
        }
        return imageURL
    }
    
    func getImageURL(uid: String) async -> URL? {
        do {
            return try await Constants.Database.profilePicsRef.child("\(uid).jpeg").downloadURL()
        } catch {
            print(error)
        }
        return nil
    }
    
    func uploadNewImage(path: String) {
        let localURL = URL(string: path)!
        let profilePicReference = Constants.Database.profilePicsRef.child("\(uid).jpeg")
        
        profilePicReference.putFile(from: localURL, metadata: nil) { metadata, error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func uploadNewImage(data: Data) {
        let profilePicReference = Constants.Database.profilePicsRef.child("\(uid).jpeg")
        
        print("DEBUG: Profile picture reference is \(profilePicReference)")
        profilePicReference.putData(data, metadata: nil) { metadata, error in
            if let error = error {
                print("DEBUG: \(error)")
            }
        }
    }
    
    func getUID() -> String {
        return uid
    }
    
}
