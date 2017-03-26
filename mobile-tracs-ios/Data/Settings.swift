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
            global_disable = dict["global_disable"] as! Bool
            for entrydict in dict["disabled_filters"] as! [[String:String]] {
                disabled_filters.append(SettingsEntry(dict: entrydict))
            }
        }
    }
    
    func disableSite(site:Site) {
        if !siteIsDisabled(site: site) {
            disabled_filters.append(SettingsEntry(disabled_site: site))
        }
    }
    func siteIsDisabled(site:Site)->Bool {
        return disabled_filters.contains(SettingsEntry(disabled_site:site))
    }
    
    func disableObjectType(type:String) {
        if !objectTypeIsDisabled(type: type) {
            disabled_filters.append(SettingsEntry(disabled_type: type))
        }
    }
    func objectTypeIsDisabled(type:String)->Bool {
        return disabled_filters.contains(SettingsEntry(disabled_type: type))
    }
    
    func toJSONObject() -> Any {
        return [
            "global_disable": global_disable,
            "disabled_filters": disabled_filters.toJSONObject()
        ]
    }
}
