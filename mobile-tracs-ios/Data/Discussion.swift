//
//  Discussion.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/2/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Discussion : TRACSObjectBase, TRACSObject {
    static let type = "discussion"
    static let display = "Forum Post"
    static let displayplural = "Forum Posts"
    
    var title = ""
    var body = ""
    
    override init(dict:[String:Any]) {
        super.init(dict:dict)
        title = dict["title"] as? String ?? ""
        body = dict["body"] as? String ?? ""
    }
    
    func tableTitle()->String {
        return title
    }
    
    func getUrl()->String {
        return site?.discussionurl ?? ""
    }
    
    func getType()->String {
        return Discussion.type
    }
}
