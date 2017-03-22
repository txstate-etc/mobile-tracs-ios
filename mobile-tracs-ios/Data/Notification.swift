//
//  Notification.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Notification {
    public var id: Int?
    public var notification_type: String?
    public var object_type: String?
    public var object_id: String?
    public var object: TRACSObject?
    public var context_id: String?
    public var content_hash: String?
    public var notify_after: Date?
    public var read: Bool
    public var cleared: Bool

    init(dict:[String:Any]) {
        id = dict["id"] as? Int
        notification_type = dict["notification_type"] as? String
        object_type = dict["object_type"] as? String
        object_id = dict["object_id"] as? String
        context_id = dict["context_id"] as? String
        content_hash = dict["content_hash"] as? String
        notify_after = dict["notify_after"] as? Date
        read = dict["read"] as? Bool ?? false
        cleared = dict["cleared"] as? Bool ?? false
    }    
}
