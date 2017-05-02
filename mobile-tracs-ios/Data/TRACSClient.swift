//
//  TRACSClient.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class TRACSClient {
    // MARK: - URL Constants
    static let tracsurl = Secrets.shared.tracsbaseurl ?? "https://tracs.txstate.edu"
    static let baseurl = tracsurl+"/direct"
    static let announcementurl = baseurl+"/announcement"
    static let membershipurl = baseurl+"/membership"
    static let siteurl = baseurl+"/site"
    static let portalurl = tracsurl+"/portal"
    static let loginurl = tracsurl+"/portal/login"
    static let deeploginurl = tracsurl+"/sakai-login-tool"
    static let logouturl = tracsurl+"/portal/pda/?force.logout=yes"
    static let altlogouturl = tracsurl+"/portal/logout"
    
    // MARK: - Static Variables
    private static var tracslockqueue = DispatchQueue(label: "tracslock")
    static var sitecache = Cache(cacheName: "sitecache")
    static var userid = ""
    
    // MARK: - Fetch data from TRACS
    static func waitForLogin(completion:@escaping(Bool)->Void) {
        tracslockqueue.async {
            DispatchQueue.main.async {
                completion(!userid.isEmpty)
            }
        }
    }
    
    static func fetchAnnouncement(id:String, completion:@escaping (Announcement?)->Void) {
        tracslockqueue.async {
            Utils.fetchJSONObject(url: announcementurl+"/"+id+".json") { (parsed) in
                if parsed == nil { return completion(nil) }
                return completion(Announcement(dict: parsed!))
            }
        }
    }
    
    static func fetchDiscussion(id:String, completion:@escaping (Discussion?)->Void) {
        tracslockqueue.async {
            Utils.fetchJSONObject(url: baseurl+"/"+id+".json") { (parsed) in
                if parsed == nil { return completion(nil) }
                return completion(Discussion(dict: parsed!))
            }
        }
    }
    
    // returns a hash of all the user's sites
    static func fetchSites(completion:@escaping([String:Site]?)->Void) {
        tracslockqueue.async {
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
    }
    
    // returns a hash of all the user's sites
    static func fetchSitesByMembership(completion:@escaping([String:Site]?)->Void) {
        tracslockqueue.async {
            Utils.fetchJSONObject(url: membershipurl+".json") { (dict) in
                if (dict == nil) { return completion(nil) }
                let membs = dict!["membership_collection"] as? [[String:Any]] ?? []
                var siteids:[String] = []
                for memb in membs {
                    if let loc = memb["locationReference"] as? String {
                        let sid = loc.substring(from: loc.index(loc.startIndex, offsetBy: 6))
                        siteids.append(sid)
                    }
                }
                fetchSitesById(siteids: siteids, completion: { (sitehash) in
                    completion(sitehash)
                })
            }
        }
    }

    
    static func fetchSite(id:String, completion:@escaping(Site?)->Void) {
        tracslockqueue.async {
            var completionsent = false
            var shouldrefresh = true
            if let site = sitecache.get(id) as? Site {
                shouldrefresh = site.shouldRefresh()
                completionsent = true
                completion(site)
            }
            if shouldrefresh {
                Utils.fetchJSONObject(url: siteurl+"/"+id+".json") { (parsed) in
                    if parsed == nil { return completion(nil) }
                    let site = Site(dict: parsed!)
                    sitecache.put(site)
                    if !completionsent {
                        return completion(site)
                    }
                }
            }
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
    
    // MARK: - Authentication
    static func loginIfNecessary(completion:@escaping(Bool)->Void) {
        tracslockqueue.async {
            let tracslock = DispatchGroup()
            tracslock.enter()
            checkForNewUser {
                if userid.isEmpty {
                    // try our saved credentials
                    attemptLogin(netid: Utils.netid(), password: Utils.password(), completion: { (sessionid) in
                        NSLog("login attempt made, got %@ back", sessionid)
                        if !sessionid.isEmpty {
                            checkForNewUser {
                                tracslock.leave()
                                completion(true)
                            }
                        } else {
                            userid = ""
                            Utils.removeCredentials()
                            tracslock.leave()
                            completion(false)
                        }
                    })
                } else {
                    tracslock.leave()
                    completion(true)
                }
            }
            tracslock.wait()
        }
    }

    private static func fetchCurrentUserId(completion:@escaping (String?)->Void) {
        let sessionurl = baseurl+"/session/current.json"
        Utils.fetchJSONObject(url: sessionurl) { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(parsed!["userEid"] as? String ?? "")
        }
    }
    
    private static func checkForNewUser(completion:@escaping()->Void) {
        TRACSClient.fetchCurrentUserId { (uid) in
            if let uid = uid {
                if uid.isEmpty {
                    // we got a good response but an empty userid, we are clearly logged out
                    userid = ""
                } else if uid != userid {
                    userid = uid
                }
            }
            completion()
        }
    }
    
    private static func attemptLogin(netid:String, password:String, completion:@escaping(String)->Void) {
        if netid.isEmpty || password.isEmpty { return completion("") }
        Utils.post(url: baseurl+"/session", params: ["_username":netid, "_password":password]) { (data, success) in
            if let body = data as? String {
                return completion(body.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return completion("")
        }
    }
}
