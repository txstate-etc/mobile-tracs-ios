//
//  SettingsEntry.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class SettingsEntry : Equatable, JSONRepresentable {
    public var keys:[String:String] = [:]
    public var otherkeys:[String:String] = [:]
    
    init(disabled_site:Site) {
        otherkeys = [
            "site_id": disabled_site.id
        ]
    }
    init(disabled_type:String) {
        keys = [
            "object_type": disabled_type
        ]
    }
    init(dict:[String:[String:String]]) {
        if let keys = dict["keys"] {
            self.keys = keys
        }
        if let otherkeys = dict["other_keys"] {
            self.otherkeys = otherkeys
        }
    }
    
    func valid() -> Bool {
        return otherkeys.count + keys.count > 0
    }
    
    static func == (a: SettingsEntry, b: SettingsEntry) -> Bool {
        if a.keys.count != b.keys.count { return false }
        if a.otherkeys.count != b.otherkeys.count { return false }
        for key in a.keys.keys {
            if a.keys[key] != b.keys[key] { return false }
        }
        for key in a.otherkeys.keys {
            if a.otherkeys[key] != b.otherkeys[key] { return false }
        }
        return true
    }
    
    func toJSONObject() -> Any {
        return [
            "keys": keys,
            "other_keys": otherkeys
        ]
    }
}
