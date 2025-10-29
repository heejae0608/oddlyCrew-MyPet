//
//  AppDelegate.swift
//  OurPet
//
//  Created by Assistant on 10/28/25.
//

import UIKit
import FirebaseCore

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseConfiguration.configureIfNeeded()
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}


