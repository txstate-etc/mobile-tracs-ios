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
    static let jwtserviceurl = Secrets.shared.jwtservicebaseurl ?? "http://dispatch.its.txstate.edu/token.pl"
    static let baseurl = Secrets.shared.integrationbaseurl ?? "https://dispatch.its.txstate.edu"
    static let registrationurl = baseurl+"/registrations"
    static let notificationsurl = baseurl+"/notifications"
    static let settingsurl = baseurl+"/settings"
    
    public static func getRegistration() -> Registration {
        if let registration = Utils.grab("registration") as? [String:Any] {
            return Registration(registration)
        }
        return Registration()
    }
    
    static func getRegistration(completion:@escaping(Registration)->Void) {
        Utils.fetchJSONObject(url: registrationurl+"/"+deviceToken) { (dict) in
            completion(Registration(dict))
        }
    }
    
    public static func register(_ completion:@escaping (Bool)->Void) {
        let reg = getRegistration()
        reg.token = deviceToken
        reg.user_id = TRACSClient.userid
        
        saveRegistration(reg: reg) { (success) in
            if success {
                Utils.save(deviceToken, withKey: "lastregisteredtoken")
                getBadgeCount(completion: { (badgecount) in
                    UIApplication.shared.applicationIconBadgeNumber = badgecount
                    completion(success)
                })
            } else {
                completion(false)
            }
        }
    }
    
    public static func saveRegistration(reg:Registration, completion:@escaping(Bool)->Void) {
        if reg.valid() {
            if let body = reg.toJSON() {
                Utils.fetch(jwtserviceurl, completion: { (jwt) in
                    if jwt.isEmpty || jwt.contains("<html") {
                        NSLog("did not get a good JWT from service")
                        return completion(false)
                    }
                    Utils.post(url: registrationurl+"?jwt="+jwt, body: body, completion: { (data, success) in
                        if success {
                            // save the registration details so that we don't have to do this often
                            Utils.save(reg.toJSONObject(), withKey: "registration")
                        } else {
                            NSLog("error saving registration: %@", data as? String ?? "")
                        }
                        completion(success)
                    })
                })
            }
        } else {
            NSLog("saveRegistration: reg was not valid %@ %@", reg.user_id ?? "nil", reg.token ?? "nil")
            completion(false)
        }
    }
        
    public static func unregister() {
        if !deviceToken.isEmpty {
            Utils.delete(url: registrationurl, params: ["token":deviceToken], completion: { (data, success) in
                Utils.zap("registration")
                Utils.zap("lastregisteredtoken")
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
            Utils.fetchJSONArray(url: notificationsurl+"?token="+deviceToken) { (data) in
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
            if n.object_id == nil || (n.site_id ?? "").isEmpty { continue }
            siteids.append(n.site_id!)
            if n.object_type == Announcement.type {
                dispatchgroup.enter()
                TRACSClient.fetchAnnouncement(id: n.object_id!, siteid: n.site_id!, completion: { (ann) in
                    n.object = ann
                    dispatchgroup.leave()
                })
            }
            if n.object_type == Discussion.type {
                dispatchgroup.enter()
                TRACSClient.fetchDiscussion(id: n.object_id!, completion: { (msg) in
                    n.object = msg
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
            // also create a new return array and exclude notifications with nil target objects
            NSLog("loadAll complete")
            var ret:[Notification] = []
            for n in notifications {
                if var obj = n.object {
                    if obj.read { n.read = true }
                    if !(n.site_id ?? "").isEmpty {
                        obj.site = sitehash[n.site_id!]
                    }
                    ret.append(n)
                }
            }
            completion(ret)
        }
    }
    
    static func markNotificationsSeen(_ notis:[Notification], completion:@escaping(Bool)->Void) {
        if notis.count == 0 { return completion(true) }
        let ids = notis.map { (n) -> String in
            n.id!
        }
        Utils.patch(url: notificationsurl+"?token="+deviceToken, jsonobject: ["ids":ids, "patches":["seen":true]]) { (success) in
            completion(success)
        }
    }
    
    static func markNotificationCleared(_ notify:Notification, completion:@escaping(Bool)->Void) {
        if let id = notify.id {
            Utils.patch(url: notificationsurl+"/"+id+"?token="+deviceToken, jsonobject:["cleared":true]) { (success) in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    static func markAllNotificationsCleared(_ notis:[Notification], completion:@escaping(Bool)->Void) {
        if notis.count == 0 { return completion(true) }
        let ids = notis.map { (n) -> String in
            n.id!
        }
        Utils.patch(url: notificationsurl+"?token="+deviceToken, jsonobject: ["ids":ids, "patches":["cleared":true]]) { (success) in
            completion(success)
        }
    }
    
    static func markNotificationRead(_ notify:Notification, completion:@escaping(Bool)->Void) {
        if let id = notify.id {
            Utils.patch(url: notificationsurl+"/"+id+"?token="+deviceToken, jsonobject:["read":true]) { (success) in
                completion(success)
            }
        } else {
            completion(false)
        }
    }
    
    static func getBadgeCount(completion:@escaping(Int)->Void) {
        Utils.fetchJSONObject(url: notificationsurl+"/count?token="+deviceToken) { (dict) in
            completion(dict?["count"] as? Int ?? 0)
        }
    }
    
    static func fetchSettings(completion:@escaping(Settings)->Void) {
        Utils.fetchJSONObject(url: settingsurl+"/"+deviceToken) { (dict) in
            completion(Settings(dict: dict))
        }
    }
    
    static func saveSettings(_ settings:Settings, completion:@escaping(Bool)->Void) {
        if let jsonobject = settings.toJSONObject() as? [String:Any] {
            Utils.post(url: settingsurl+"/"+deviceToken, jsonobject: jsonobject, completion: { (body, success) in
                if success {
                    let reg = getRegistration()
                    reg.settings = settings
                    Utils.save(reg.toJSONObject(), withKey: "registration")
                }
                completion(success)
            })
        } else {
            completion(false)
        }
    }
}
