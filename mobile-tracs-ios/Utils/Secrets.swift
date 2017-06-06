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
    var integrationbaseurl:String?
    var jwtservicebaseurl:String?
    var tracsbaseurl:String?
    var surveyurl:String?
    var contacturl:String?
    
    init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path) as? [String:AnyObject] {
                analyticsid = dict["analyticsid"] as? String
                integrationbaseurl = dict["integrationbaseurl"] as? String
                jwtservicebaseurl = dict["jwtservicebaseurl"] as? String
                tracsbaseurl = dict["tracsbaseurl"] as? String
                surveyurl = dict["surveyurl"] as? String
                contacturl = dict["contacturl"] as? String
            }
        }
    }
}
