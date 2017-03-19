//
//  TRACSClient.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class TRACSClient {
    static let baseurl = "https://tracs.txstate.edu/direct"
    static let announcementurl = baseurl+"/announcement"
    static var announcementcache: [String:Announcement] = [:]
    
    static func fetchAnnouncement(id:String, completion:@escaping (Announcement?)->Void) {
        Utils.fetchJSON(url: announcementurl+"/"+id+".json") { (parsed) in
            if parsed == nil { return completion(nil) }
            return completion(Announcement(dict: parsed!))
        }
    }
    
    static func fetchCurrentUserId(completion:@escaping (String?)->Void) {
        let sessionurl = baseurl+"/session/current.json"
        Utils.fetchJSON(url: sessionurl) { (parsed) in
            if parsed != nil {
                completion(parsed?["userId"] as? String)
            }
            completion(nil)
        }
    }
}
