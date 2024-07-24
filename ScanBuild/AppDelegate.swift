//
//  AppDelegate.swift
//  ScanBuild
//
//  Created by Danil Lugli on 10/06/24.
//


import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let contentView = ContentView().edgesIgnoringSafeArea(.all)
        
        // Use a UIHostingController as window root view controller.
        let window = UIWindow()
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
    
    func createAppFolder() {
            let fileManager = FileManager.default
            if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String {
                do {
                    let appFolderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(appName)
                    if !fileManager.fileExists(atPath: appFolderURL.path) {
                        try fileManager.createDirectory(at: appFolderURL, withIntermediateDirectories: true, attributes: nil)
                        print("Folder created at: \(appFolderURL.path)")
                    } else {
                        print("Folder already exists at: \(appFolderURL.path)")
                    }
                } catch {
                    print("Error creating folder: \(error)")
                }
            }
        }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    
}

