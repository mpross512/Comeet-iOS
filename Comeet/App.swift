//
//  App.swift
//  Comeet
//
//  Created by Michael Ross on 10/14/23.
//  Copyright © 2023 Ice Cream Loaf. All rights reserved.
//

import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

@main 
struct ComeetApp: App {
    @StateObject private var userService = UserService()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MasterView().environmentObject(userService)
        }
    }
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//      Auth.auth().setAPNSToken(deviceToken, type: .prod)
//    }
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification notification: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//      if Auth.auth().canHandleNotification(notification) {
//        completionHandler(.noData)
//        return
//      }
//    }
//    
//    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//      Messaging.messaging().apnsToken = deviceToken
//        print("DEBUG: Successfully set apns token")
//    }
}
