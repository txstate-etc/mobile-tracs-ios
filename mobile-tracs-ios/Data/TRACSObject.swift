//
//  TRACSObject.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class TRACSObject {
    public var id = ""
    public var table_title = ""
    public var site_id = ""
    public var site:Site?

    init(dict:[String:Any]) {
        id = dict["id"] as! String
    }
    
    func titleForTable()->String {
        return table_title
    }
    func tableSubtitle()->String {
        return site?.title ?? ""
    }
    func getUrl()->String {
        // must be overridden for compatibility with NotificationViewController
        return ""
    }
}
