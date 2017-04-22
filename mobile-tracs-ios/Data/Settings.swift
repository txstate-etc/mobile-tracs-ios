//
//  Settings.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Settings : JSONRepresentable {
    var global_disable = false
    var disabled_filters:[SettingsEntry] = []
    
    init(dict: [String:Any]?) {
        if let dict = dict {
            global_disable = dict["global_disable"] as? Bool ?? false
            for entrydict in dict["blacklist"] as? [[String:[String:String]]] ?? [] {
                let entry = SettingsEntry(dict: entrydict)
                if entry.valid() { disabled_filters.append(entry) }
            }
        }
    }
    
    func entryIsDisabled(_ targetentry: SettingsEntry)->Bool {
        return disabled_filters.contains(targetentry)
    }
    func disableEntry(_ targetentry: SettingsEntry) {
        if !entryIsDisabled(targetentry) {
            disabled_filters.append(targetentry)
        }
    }
    func enableEntry(_ targetentry: SettingsEntry) {
        disabled_filters = disabled_filters.filter { (entry) -> Bool in
            return entry != targetentry
        }
    }
    
    func disableSite(site:Site) {
        disableEntry(SettingsEntry(disabled_site: site))
    }
    func enableSite(site:Site) {
        enableEntry(SettingsEntry(disabled_site: site))
    }
    func siteIsDisabled(site:Site)->Bool {
        return entryIsDisabled(SettingsEntry(disabled_site:site))
    }
    
    func disableObjectType(type:String) {
        if !objectTypeIsDisabled(type: type) {
            disabled_filters.append(SettingsEntry(disabled_type: type))
        }
    }
    func enableObjectType(type:String) {
        enableEntry(SettingsEntry(disabled_type: type))
    }
    func objectTypeIsDisabled(type:String)->Bool {
        return entryIsDisabled(SettingsEntry(disabled_type: type))
    }
    
    func toJSONObject() -> Any {
        return [
            "global_disable": global_disable,
            "blacklist": disabled_filters.toJSONObject()
        ]
    }
}
