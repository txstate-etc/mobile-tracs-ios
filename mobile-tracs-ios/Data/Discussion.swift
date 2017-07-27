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
    static let icon = FontAwesome.comments
    
    var title: String = ""
    var subtitle: String = ""
    
    override init(dict:[String:Any]) {
        super.init(dict:dict)
        title = dict["title"] as? String ?? ""
        subtitle = "Posted by: \(dict["authoredBy"] as? String ?? "")"
        let regex = try! NSRegularExpression(pattern: "\\s\\(([^)]+)\\)", options: NSRegularExpression.Options.caseInsensitive)
        let range = NSMakeRange(0, subtitle.characters.count)
        subtitle = regex.stringByReplacingMatches(in: subtitle, options: [], range: range, withTemplate: "")
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
    
    func getIcon() -> FontAwesome {
        return .comments
    }
}
