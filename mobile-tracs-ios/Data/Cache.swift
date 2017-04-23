//
//  Cache.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Cache {
    var name:String
    var hash:[String:Cacheable]
    
    init(cacheName:String) {
        name = cacheName
        hash = Utils.grab(name) as? [String:Cacheable] ?? [:]
    }
    
    func reset() {
        hash = [:]
        Utils.zap(name)
    }
    
    func clean() {
        for (key,obj) in hash {
            if obj.isExpired() {
                hash.removeValue(forKey: key)
            }
        }
    }
    
    func get(_ id:String) -> Cacheable? {
        var ret:Cacheable? = nil
        if let obj = hash[id] {
            if !obj.isExpired() {
                ret = obj
            }
        }
        return ret
    }
    
    func put(_ obj:Cacheable) {
        clean()
        hash[obj.id] = obj
        Utils.save(hash, withKey: name)
    }
}
