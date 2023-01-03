//
//  AppDelegate.swift
//  Comeet
//
//  Created by Michael Ross on 7/7/20.
//  Copyright © 2020 Ice Cream Loaf. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import SDWebImageSwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        FirebaseApp.configure()
        
        //Firestore.firestore().settings.isPersistenceEnabled = true
        
        
        //let cache = SDImageCache(namespace: "cache1")
        //cache.config.maxMemoryCost = 100 * 1024 * 1024 // 100MB memory
        //cache.config.maxDiskSize = 50 * 1024 * 1024 // 50MB disk
        //SDImageCachesManager.shared.addCache(cache)
        
        //SDWebImageManager.defaultImageCache = SDImageCachesManager.shared
        
        //SDWebImageManager.shared.optionsProcessor = SDWebImageOptionsProcessor() { url, options, context in
        //    var mutableOptions = options
        //    mutableOptions.insert(.progressiveLoad)
        //    return SDWebImageOptionsResult(options: mutableOptions, context: context)
        //}
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

