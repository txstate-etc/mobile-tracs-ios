//
//  TRACSClient.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class TRACSClient {
    static let tracsurl = "https://tracs.txstate.edu"
    static let baseurl = tracsurl+"/direct"
    static let announcementurl = baseurl+"/announcement"
    static let siteurl = baseurl+"/site"
    static let portalurl = tracsurl+"/portal"
    static let loginurl = tracsurl+"/portal/login"
    static let deeploginurl = tracsurl+"/sakai-login-tool"
    static let logouturl = tracsurl+"/portal/pda/?force.logout=yes"
    static let altlogouturl = tracsurl+"/portal/logout"
    static var announcementcache: [String:Announcement] = [:]
    public static var userid = ""
    public static var associatedsessionid = ""
    
    static func fetchAnnouncement(id:String, completion:@escaping (Announcement?)->Void) {
        Utils.fetchJSONObject(url: announcementurl+"/"+id+".json") { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(Announcement(dict: parsed!))
        }
    }
    
    static func fetchCurrentUserId(completion:@escaping (String)->Void) {
        let sessionurl = baseurl+"/session/current.json"
        Utils.fetchJSONObject(url: sessionurl) { (parsed) in
            if parsed == nil { return completion("") }
            return completion(parsed!["userId"] as? String ?? "")
        }
    }
    
    // returns a hash of all the user's sites
    static func fetchSites(completion:@escaping([String:Site]?)->Void) {
        Utils.fetchJSONObject(url: siteurl+".json") { (dict) in
            if (dict == nil) { return completion(nil) }
            var ret: [String:Site] = [:]
            let sitecollection = dict!["site_collection"] as? [[String:Any]] ?? []
            for site in sitecollection {
                let siteobj = Site(dict: site)
                if !siteobj.id.isEmpty {
                    ret[siteobj.id] = siteobj
                }
            }
            completion(ret)
        }
    }
    
    static func fetchSite(id:String, completion:@escaping(Site?)->Void) {
        Utils.fetchJSONObject(url: siteurl+"/"+id+".json") { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(Site(dict: parsed!))
        }
    }
    
    static func fetchSitesById(siteids:[String], completion:@escaping([String:Site])->Void) {
        let uniquesiteids = Set(siteids)
        var sitehash:[String:Site] = [:]
        
        let dispatchgroup = DispatchGroup()
        
        for siteid in uniquesiteids {
            dispatchgroup.enter()
            fetchSite(id: siteid, completion: { (site) in
                if site != nil && !site!.id.isEmpty {
                    sitehash[site!.id] = site
                }
                dispatchgroup.leave()
            })
        }
        
        dispatchgroup.notify(queue: .main) { 
            completion(sitehash)
        }
    }
    
    static func attemptLogin(netid:String, password:String, completion:@escaping(String)->Void) {
        if netid.isEmpty || password.isEmpty { return completion("") }
        Utils.post(url: baseurl+"/session", params: ["_username":netid, "_password":password]) { (data, success) in
            if let body = data as? String {
                return completion(body.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return completion("")
        }
    }
    
    static func loginIfNecessary(completion:@escaping(Bool)->Void) {
        fetchCurrentUserId { (uid) in
            if uid.isEmpty {
                // try our saved credentials
                attemptLogin(netid: Utils.netid(), password: Utils.password(), completion: { (sessionid) in
                    NSLog("login attempt made, got %@ back", sessionid)
                    if !sessionid.isEmpty {
                        checkForNewUser(completion: {
                            completion(true)
                        })
                    } else {
                        Utils.removeCredentials()
                        completion(false)
                    }
                })
            } else {
                completion(true)
            }
        }
    }
    
    static func checkForNewUser(completion:@escaping()->Void) {
        TRACSClient.fetchCurrentUserId { (uid) in
            if !uid.isEmpty {
                if uid != userid {
                    userid = uid
                    IntegrationClient.register()
                    return completion()
                }
            }
            completion()
        }
    }
}
