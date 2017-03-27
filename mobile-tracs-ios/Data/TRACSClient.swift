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
    static let starturl = tracsurl+"/portal/login"
    static var announcementcache: [String:Announcement] = [:]
    public static var userid = ""
    public static var associatedsessionid = ""
    
    static func fetchAnnouncement(id:String, completion:@escaping (Announcement?)->Void) {
        Utils.fetchJSONObject(url: announcementurl+"/"+id+".json") { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(Announcement(dict: parsed!))
        }
    }
    
    static func fetchCurrentUserId(completion:@escaping (String?)->Void) {
        let sessionurl = baseurl+"/session/current.json"
        Utils.fetchJSONObject(url: sessionurl) { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(parsed!["userId"] as? String)
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
        var total = uniquesiteids.count
        var sitehash:[String:Site] = [:]
        let checkforcompletion: ()->Void = {
            total -= 1
            if total <= 0 {
                completion(sitehash)
            }
        }
        
        for siteid in uniquesiteids {
            fetchSite(id: siteid, completion: { (site) in
                if site != nil && !site!.id.isEmpty {
                    sitehash[site!.id] = site
                }
                checkforcompletion()
            })
        }
    }
    
    static func checkForNewUser(runifuserchanged:@escaping()->Void) {
        var currentcookieid = ""
        for cookie in HTTPCookieStorage.shared.cookies(for: URL(string:tracsurl)!)! {
            if cookie.name.lowercased() == "jsessionid" {
                currentcookieid = cookie.value
            }
        }
        if userid.isEmpty || associatedsessionid != currentcookieid {
            TRACSClient.fetchCurrentUserId { (uid) in
                if !(uid ?? "").isEmpty {
                    associatedsessionid = currentcookieid
                    if uid != userid {
                        userid = uid!
                        IntegrationClient.register()
                        runifuserchanged()
                    }
                }
            }
        }
    }
}
