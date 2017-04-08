//
//  Notification.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Notification {
    public var id: String?
    public var provider_id: String?
    public var user_id: String?
    public var object_type: String?
    public var object_id: String?
    public var object: TRACSObject?
    public var notification_type: String?
    public var site_id: String?
    public var tool_id: String?
    public var notify_after: Date?
    public var seen: Bool
    public var read: Bool

    init(dict:[String:Any]) {
        id = dict["id"] as? String
        if let keys:[String:Any] = dict["keys"] as? [String:Any] {
            notification_type = keys["notification_type"] as? String
            object_type = keys["object_type"] as? String
            object_id = keys["object_id"] as? String
            user_id = keys["user_id"] as? String
            provider_id = keys["provider_id"] as? String
        }
        if let otherkeys:[String:Any] = dict["otherkeys"] as? [String:Any] {
            site_id = otherkeys["site_id"] as? String
            tool_id = otherkeys["tool_id"] as? String
        }
        notify_after = dict["notify_after"] as? Date
        seen = dict["seen"] as? Bool ?? false
        read = dict["read"] as? Bool ?? false
    }
}
