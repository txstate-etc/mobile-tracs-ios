//
//  Announcement.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Announcement {
    public var id: String = ""
    public var title: String = ""
    public var body: String = ""
    
    init(dict:[String:Any]) {
        id = dict["id"] as! String
        title = dict["title"] as! String
        body = dict["body"] as! String
    }
}
