//
//  IntegrationClient.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class IntegrationClient {
    static var deviceToken = ""
    static let baseurl = "https://notifications.its.txstate.edu"
    static let registrationurl = baseurl+"/registrations"
    static let notificationsurl = baseurl+"/notifications"
    static let settingsurl = baseurl+"/settings"
    
    public static func register() {
        // are we already registered?
        var savedreg:Registration?
        if let registration = UserDefaults.standard.value(forKey: "registration") as? [String:Any] {
            savedreg = Registration(registration)
        }
        
        let newreg = Registration()
        if newreg != savedreg && newreg.valid() {
            // register with the integration server
            if let body = newreg.toJSON() {
                Utils.post(url: registrationurl, body: body, completion: { (data, success) in
                    NSLog("attempted registration with integration server")
                    if success {
                        // save the registration details so that we don't have to do this often
                        UserDefaults.standard.set(newreg.toJSONObject(), forKey: "registration")
                    }
                })
            }
        }
    }
    
    public static func unregister() {
        if !deviceToken.isEmpty {
            Utils.delete(url: registrationurl, params: ["token":deviceToken], completion: { (data, success) in
                UserDefaults.standard.removeObject(forKey: "registration")
            })
        }
    }
   
    static func getNotification(id:String, completion:@escaping(Notification?)->Void) {
        Utils.fetchJSONObject(url: notificationsurl+"/"+id) { (dict) in
            if (dict == nil) { return completion(nil) }
            completion(Notification(dict: dict!))
        }
    }
    
    // this is the primary function for loading data in the notifications screen
    // it automatically calls loadAll to get related data
    static func getNotifications(completion:@escaping([Notification]?)->Void) {
        TRACSClient.waitForLogin { (loggedin) in
            if !loggedin { return completion(nil) }
            Utils.fetchJSONArray(url: notificationsurl+"?user_id="+TRACSClient.userid) { (data) in
                if (data == nil) { return completion(nil) }
                var ret:[Notification] = []
                for notifyjson in data! {
                    ret.append(Notification(dict: notifyjson as! [String : Any]))
                }
                loadAll(notifications: ret, completion: { (fillednotifications) in
                    completion(fillednotifications)
                })
            }
        }
    }
    
    // this func interacts with the TRACSClient to fetch all the LMS data for current notifications
    // it runs the API requests in parallel and calls the completion handler when all of them
    // are done
    static func loadAll(notifications:[Notification], completion:@escaping([Notification])->Void) {
        var sitehash:[String:Site] = [:]
        var siteids:[String] = []
        
        let dispatchgroup = DispatchGroup()
        
        // then we start requests for each notification to fetch the LMS data for its
        // TRACSObject
        for n in notifications {
            if n.object_id == nil { continue }
            if !(n.site_id ?? "").isEmpty {
                siteids.append(n.site_id!)
            }
            if n.object_type == Announcement.type {
                dispatchgroup.enter()
                TRACSClient.fetchAnnouncement(id: n.object_id!, completion: { (ann) in
                    n.object = ann
                    dispatchgroup.leave()
                })
            }
        }
        
        // here we fetch all the sites so that we can
        // map them into the TRACSObjects that relate to each Notification
        dispatchgroup.enter()
        TRACSClient.fetchSitesById(siteids: siteids, completion: { (sh) in
            sitehash = sh
            dispatchgroup.leave()
        })
        
        dispatchgroup.notify(queue: .main) { 
            // add the Site into each TRACSObject
            NSLog("loadAll complete")
            for n in notifications {
                if n.object != nil && !(n.site_id ?? "").isEmpty {
                    n.object!.site = sitehash[n.site_id!]
                }
            }
            completion(notifications)
        }
    }
    
    static func markNotificationsSeen(notifications:[Notification], completion:@escaping(Bool)->Void) {
        completion(true)
    }
    
    static func fetchSettings(completion:@escaping(Settings)->Void) {
        TRACSClient.waitForLogin { (loggedin) in
            Utils.fetchJSONObject(url: settingsurl+"?token="+deviceToken) { (dict) in
                completion(Settings(dict: dict))
            }
        }
    }
    
    static func saveSettings(_ settings:Settings) {
        Utils.post(url: settingsurl, body: settings.toJSON()!) { (data, success) in
        }
    }
}
