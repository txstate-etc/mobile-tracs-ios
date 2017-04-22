//
//  Registration.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/7/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Registration : JSONRepresentable, Equatable {
    var user_id:String?
    var token:String?
    var platform:String?
    var app_id:String?
    var settings:Settings?
    
    init(_ dict:[String:Any]?) {
        if let dict = dict {
            user_id = dict["user_id"] as? String
            token = dict["token"] as? String
            platform = dict["platform"] as? String
            app_id = dict["app_id"] as? String
            settings = Settings(dict: dict)
        }
    }
    
    init() {
        user_id = TRACSClient.userid
        token = IntegrationClient.deviceToken
        platform = "ios"
        app_id = Bundle.main.bundleIdentifier
    }
    
    func valid() -> Bool {
        return !(user_id ?? "").isEmpty && !(token ?? "").isEmpty
    }
    
    func toJSONObject() -> Any {
        return [
            "user_id": user_id ?? "",
            "token": token ?? "",
            "platform": platform ?? "",
            "app_id": app_id ?? "",
            "global_disable": settings?.global_disable ?? false,
            "blacklist": settings?.disabled_filters.toJSONObject() ?? []
        ]
    }
    
    static func == (a:Registration, b:Registration) -> Bool {
        return a.user_id == b.user_id && a.token == b.token
    }
}
