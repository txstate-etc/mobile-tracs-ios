//
//  AppDelegate.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/17/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Clear out cache data between versions in case we change the structure of the object being saved
        if let savedversion = Utils.grab("version") as? String {
            if let currentversion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                if currentversion != savedversion {
                    TRACSClient.sitecache.clean()
                    Utils.save(currentversion, withKey: "version")
                }
            }
        }
        
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        let wvc = WebViewController(nibName: "WebViewController", bundle: nil)
        let nav = UINavigationController()
        nav.navigationBar.barStyle = .default
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.barTintColor = Utils.gray
        nav.navigationBar.tintColor = Utils.darkred
        nav.viewControllers = [wvc]
        window?.rootViewController = nav
        window?.backgroundColor = UIColor.white
        window?.makeKeyAndVisible()
        
        //Set a custom user agent so that UIWebView and URLSession dataTasks will match
        UserDefaults.standard.register(defaults: ["UserAgent": Utils.userAgent])
        
        // register for push notifications
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                if error == nil && granted { application.registerForRemoteNotifications() }
            }
            center.delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
                
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        TRACSClient.loginIfNecessary { (loggedin) in
            
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IntegrationClient.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        NSLog("deviceToken: %@", IntegrationClient.deviceToken)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        Analytics.event(category: "External Launch", action: url.absoluteString, label: sourceApplication ?? "null", value: nil)
        return true
    }
    
    func getActiveViewController() -> NotificationObserver? {
        let top = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
        return top?.viewControllers.last as? NotificationObserver
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if application.applicationState == .active {
            NSLog("received notification: %@", userInfo)
            if let observer = getActiveViewController() {
                var badge:Int?
                var msg:String?
                if let aps = userInfo["aps"] as? [String:Any] {
                    badge = aps["badge"] as? Int
                    msg = aps["alert"] as? String
                }
                observer.incomingNotification(badgeCount: badge, message: msg)
            }
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("userNotificationCenter %i %@", notification.request.content.badge ?? 0, notification.request.content.body)
        if let observer = getActiveViewController() {
            observer.incomingNotification(badgeCount: notification.request.content.badge as? Int, message: notification.request.content.body)
        }
        completionHandler([.alert, .badge])
    }
}

