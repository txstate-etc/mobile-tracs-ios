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
            center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                if error == nil && granted { application.registerForRemoteNotifications() }
            }
            center.delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        if IntegrationClient.deviceToken.isEmpty {
            IntegrationClient.deviceToken = (Utils.grab("deviceToken") as? String) ?? ""
        }
        if IntegrationClient.deviceToken.isEmpty {
            IntegrationClient.deviceToken = Utils.randomHexString(length:32)
            Utils.save(IntegrationClient.deviceToken, withKey: "deviceToken")
        }
        if let lastregisteredtoken = Utils.grab("lastregisteredtoken") as? String {
            if IntegrationClient.deviceToken != lastregisteredtoken {
                Utils.removeCredentials()
            }
        }

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
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        Analytics.event(category: "External Launch", action: url.absoluteString, label: sourceApplication ?? "null", value: nil)
        return true
    }
    
    func reloadEverything() {
        let current = getCurrentViewController()
        if current?.presentedViewController != nil {
            current?.dismiss(animated: true, completion: nil)
        }
        
        let top = getNavController()
        top?.popToRootViewController(animated: true)
        
        let wvc = getWebViewController()
        wvc?.load()
    }
    
    func getNavController() -> UINavigationController? {
        return UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
    }
    
    func getWebViewController() -> WebViewController? {
        let top = getNavController()
        return top?.viewControllers.first as? WebViewController
    }
    
    func getActiveNotificationObserver() -> NotificationObserver? {
        let top = getNavController()
        return top?.viewControllers.last as? NotificationObserver
    }
    
    func getCurrentViewController() -> UIViewController? {
        let top = getNavController()
        return top?.viewControllers.last
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if application.applicationState == .active {
            if let observer = getActiveNotificationObserver() {
                var badge:Int?
                var msg:String?
                if let aps = userInfo["aps"] as? [String:Any] {
                    badge = aps["badge"] as? Int
                    msg = aps["alert"] as? String
                }
                UIApplication.shared.applicationIconBadgeNumber = badge ?? 0
                observer.incomingNotification(badgeCount: badge, message: msg)
            }
        }
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = notification.request.content.badge?.intValue ?? 0
        if let observer = getActiveNotificationObserver() {
            observer.incomingNotification(badgeCount: notification.request.content.badge?.intValue, message: notification.request.content.body)
        }
        completionHandler([.alert, .badge])
    }
}

