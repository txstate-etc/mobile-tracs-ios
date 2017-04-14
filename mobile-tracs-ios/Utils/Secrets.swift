//
//  Secrets.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/13/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Secrets {
    static let shared = Secrets()
    var analyticsid:String?
    
    init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String:AnyObject] {
                analyticsid = dict["analyticsid"] as? String
            }
        }
    }
}
