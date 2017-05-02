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
    var announcementurl = ""
    var discussionurl = ""
    var created_at:Date
    
    init(dict:[String:Any]) {
        id = dict["id"] as? String ?? ""
        title = dict["title"] as? String ?? ""
        coursesite = dict["type"] as? String == "course"
        for page in dict["sitePages"] as? [[String:Any]] ?? [] {
            if page["title"] as? String == "Announcements" {
                announcementurl = page["url"] as? String ?? ""
            }
            if page["title"] as? String == "Forums" {
                discussionurl = page["url"] as? String ?? ""
            }
        }
        created_at = Date()
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
