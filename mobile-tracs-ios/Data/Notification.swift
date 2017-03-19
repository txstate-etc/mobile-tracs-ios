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
    
    static func loadAll(notifications:[Notification], completion:@escaping([Notification])->Void) {
        var total = notifications.count
        let checkforcompletion: ()->Void = {
            total -= 1
            if total <= 0 { completion(notifications) }
        }
        for n in notifications {
            if n.object_id == nil {
                total -= 1
                continue
            }
            if n.object_type == "announcement" {
                TRACSClient.fetchAnnouncement(id: n.object_id!, completion: { (ann) in
                    n.object = ann
                    checkforcompletion()
                })
            } else {
                total -= 1
            }
        }
        checkforcompletion()
    }
}
