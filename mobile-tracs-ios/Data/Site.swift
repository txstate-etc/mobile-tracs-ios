//
//  Site.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/21/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Site {
    var id = ""
    var coursesite = false
    var title = ""
    var announcementurl = ""
    
    init(dict:[String:Any]) {
        id = dict["id"] as? String ?? ""
        title = dict["title"] as? String ?? ""
        coursesite = dict["type"] as? String == "course"
        for page in dict["sitePages"] as? [[String:Any]] ?? [] {
            if page["title"] as? String == "Announcements" {
                announcementurl = page["url"] as? String ?? ""
            }
        }
    }
}
