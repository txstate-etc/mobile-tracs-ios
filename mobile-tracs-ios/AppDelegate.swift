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
        
        // register for push notifications
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in }
            center.delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        //Set a custom user agent so that UIWebView and URLSession dataTasks will match
        UserDefaults.standard.register(defaults: ["UserAgent": Utils.userAgent])
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if self.window?.rootViewController?.presentedViewController is LoginViewController {
            return UIInterfaceOrientationMask.portrait
        } else {
            return UIInterfaceOrientationMask.all
        }
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
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        IntegrationClient.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Utils.save(IntegrationClient.deviceToken, withKey: "deviceToken")
        NSLog("deviceToken: %@", IntegrationClient.deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        IntegrationClient.deviceToken = Utils.randomHexString(length:32)
        Utils.save(IntegrationClient.deviceToken, withKey: "deviceToken")
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        Analytics.event(category: "External Launch", action: url.absoluteString, label: sourceApplication ?? "null", value: nil)
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ObservableEvent.PUSH_NOTIFICATION), object: self)
        var badge:Int?
        if let aps = userInfo["aps"] as? [String:Any] {
            badge = aps["badge"] as? Int
        }
        UIApplication.shared.applicationIconBadgeNumber = badge ?? 0
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let tabController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController
        tabController?.selectedIndex = 1
        let navController = tabController?.selectedViewController as? UINavigationController
        navController?.popToRootViewController(animated: true)
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ObservableEvent.PUSH_NOTIFICATION), object: self)
        UIApplication.shared.applicationIconBadgeNumber = notification.request.content.badge?.intValue ?? 0
        completionHandler([.alert, .badge])
    }
}

