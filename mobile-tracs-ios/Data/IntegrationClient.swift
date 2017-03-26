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
    static let registrationurl = baseurl+"/registration"
    static let notificationsurl = baseurl+"/notifications"
    static let settingsurl = baseurl+"/settings"
    
    public static func register() {
        // are we already registered?
        let registration = UserDefaults.standard.value(forKey: "registration") as? [String:String]
        if registration == nil || registration?["userId"] != TRACSClient.userid || registration?["deviceToken"] != deviceToken {
            // do we have enough information to register?
            if TRACSClient.userid.isEmpty || deviceToken.isEmpty {
                return
            }
            
            // register with the integration server
            let reg = ["app_id": "tracs_ios", "user_id": TRACSClient.userid, "device_id":deviceToken]
            Utils.post(url: registrationurl, params: reg, completion: { (data, success) in
                NSLog("attempted registration with integration server")
                if success {
                    // save the registration details so that we don't have to do this often
                    UserDefaults.standard.set(["userId":TRACSClient.userid, "deviceToken":deviceToken], forKey: "registration")
                }
            })
        }
    }
    
    public static func unregister() {
        TRACSClient.userid = ""
        UserDefaults.standard.removeObject(forKey: "registration")
        if !deviceToken.isEmpty {
            Utils.delete(url: registrationurl, params: ["device_id":deviceToken], completion: { (data, success) in
                // not sure if we need to do anything here
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
        Utils.fetchJSONArray(url: notificationsurl+"?device_id="+deviceToken) { (data) in
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
    
    // this func interacts with the TRACSClient to fetch all the LMS data for current notifications
    // it runs the API requests in parallel and calls the completion handler when all of them
    // are done
    static func loadAll(notifications:[Notification], completion:@escaping([Notification])->Void) {
        var total = notifications.count+1
        var sitehash:[String:Site] = [:]
        var siteids:[String] = []
        
        let checkforcompletion: ()->Void = {
            total -= 1
            if total <= 0 {
                // add the Site into each TRACSObject
                NSLog("loadAll complete")
                for n in notifications {
                    if n.object != nil && !(n.context_id ?? "").isEmpty {
                        n.object!.site = sitehash[n.context_id!]
                    }
                }
                completion(notifications)
            }
        }
        
        // then we start requests for each notification to fetch the LMS data for its
        // TRACSObject
        for n in notifications {
            if n.object_id == nil {
                checkforcompletion()
                continue
            }
            if !(n.context_id ?? "").isEmpty {
                siteids.append(n.context_id!)
            }
            if n.object_type == Announcement.type {
                TRACSClient.fetchAnnouncement(id: n.object_id!, completion: { (ann) in
                    n.object = ann
                    checkforcompletion()
                })
            } else {
                checkforcompletion()
            }
        }
        
        // here we fetch all the sites so that we can
        // map them into the TRACSObjects that relate to each Notification
        TRACSClient.fetchSitesById(siteids: siteids, completion: { (sh) in
            sitehash = sh
            checkforcompletion()
        })
    }
    
    static func fetchSettings(completion:@escaping(Settings)->Void) {
        Utils.fetchJSONObject(url: settingsurl) { (dict) in
            completion(Settings(dict: dict))
        }
    }
}
