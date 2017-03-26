//
//  SettingsEntry.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class SettingsEntry : Equatable, JSONRepresentable {
    public var filters:[String:String] = [:]
    
    init(disabled_site:Site) {
        filters = [
            "site_id": disabled_site.id
        ]
    }
    init(disabled_type:String) {
        filters = [
            "object_type": disabled_type
        ]
    }
    init(dict:[String:String]) {
        filters = dict
    }
    static func == (a: SettingsEntry, b: SettingsEntry) -> Bool {
        if a.filters.count != b.filters.count { return false }
        for key in a.filters.keys {
            if a.filters[key] != b.filters[key] { return false }
        }
        return true
    }
    
    func toJSONObject() -> Any {
        return filters
    }
}
