//
//  JSONSerialize.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

protocol JSONRepresentable {
    func toJSONObject()->Any
}

extension JSONRepresentable {
    func toJSON() -> String? {
        let jsonobject = toJSONObject()
        
        guard JSONSerialization.isValidJSONObject(jsonobject) else {
            print("Invalid JSON Representation")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonobject, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }    
}

extension Array where Element: JSONRepresentable {
    func toJSONObject()->[Any] {
        return self.map({ (o) -> Any in
            return o.toJSONObject()
        })
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: JSONRepresentable {
    func toJSONObject()->[String:Any] {
        var ret:[String:Any] = [:]
        for (key, val) in self {
            ret[key as! String] = val.toJSONObject()
        }
        return ret
    }
}
