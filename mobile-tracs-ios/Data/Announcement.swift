//
//  Announcement.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Announcement : TRACSObject {
    public var title: String = ""
    public var body: String = ""
    
    override init(dict:[String:Any]) {
        super.init(dict: dict)
        title = dict["title"] as! String
        body = dict["body"] as! String
    }
}
