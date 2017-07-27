//
//  Announcement.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Announcement : TRACSObjectBase, TRACSObject {
    static let type = "announcement"
    static let display = "Announcement"
    static let displayplural = "Announcements"
    
    var title = ""
    var subtitle = ""
    
    override init(dict:[String:Any]) {
        super.init(dict:dict)
        title = dict["title"] as? String ?? ""
        subtitle = "Created by: \(dict["createdByDisplayName"] as? String ?? "")"
    }
    
    func tableTitle()->String {
        return title
    }

    func getUrl()->String {
        return site?.announcementurl ?? ""
    }
    
    func getType()->String {
        return Announcement.type
    }
    
    func getIcon() -> FontAwesome {
        return .bullhorn
    }
}
