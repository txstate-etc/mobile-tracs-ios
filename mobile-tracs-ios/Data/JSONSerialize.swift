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

class JSON {
    static func toJSON(_ obj:Any)->String? {
        var final = obj
        if let obj = obj as? JSONRepresentable {
            final = obj.toJSONObject()
        }
        
        guard JSONSerialization.isValidJSONObject(final) else {
            print("Invalid JSON Representation")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: final, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

extension JSONRepresentable {
    func toJSON() -> String? {
        return JSON.toJSON(self)
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
