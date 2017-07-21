//
//  Site.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/21/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Site : NSObject, Cacheable {
    var id = ""
    var coursesite = false
    var title = ""
    var hasannouncements = false
    var hasdiscussions = false
    var announcementurl = ""
    var discussionurl = ""
    var created_at:Date
    var invalid = false
    
    init(dict:[String:Any]) {
        id = dict["id"] as? String ?? ""
        title = dict["title"] as? String ?? ""
        coursesite = dict["type"] as? String == "course"
        created_at = Date()
        invalid = (dict["sitePages"] as? [Any] ?? []).count == 0
    }
    
    func findUrls(jsonarray: [Any]) {
        for page in jsonarray as? [[String:Any]] ?? [] {
            for tool in page["tools"] as? [[String:Any]] ?? [] {
                if tool["toolId"] as? String == "sakai.announcements" {
                    hasannouncements = true
                    announcementurl = tool["url"] as? String ?? ""
                }
                if tool["toolId"] as? String == "sakai.forums" {
                    hasdiscussions = true
                    discussionurl = tool["url"] as? String ?? ""
                }
            }
        }
    }
    
    func valid() -> Bool {
        return !id.isEmpty && !invalid && (!announcementurl.isEmpty || !discussionurl.isEmpty)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey:"id")
        aCoder.encode(coursesite, forKey:"coursesite")
        aCoder.encode(title, forKey:"title")
        aCoder.encode(announcementurl, forKey:"announcementurl")
        aCoder.encode(discussionurl, forKey:"discussionurl")
        aCoder.encode(created_at, forKey:"created_at")
    }
    
    required init(coder: NSCoder) {
        id = coder.decodeObject(forKey: "id") as? String ?? ""
        coursesite = coder.decodeObject(forKey: "coursesite") as? Bool ?? false
        title = coder.decodeObject(forKey: "title") as? String ?? ""
        announcementurl = coder.decodeObject(forKey: "announcementurl") as? String ?? ""
        discussionurl = coder.decodeObject(forKey: "discussionurl") as? String ?? ""
        created_at = coder.decodeObject(forKey: "createdat") as? Date ?? Date(timeIntervalSince1970: 0)
    }
}
