//
//  IntegrationClient.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class IntegrationClient {
    static var deviceToken = ""
    static let baseurl = "https://notifications.its.txstate.edu"
    static let registrationurl = baseurl+"/registration"
    
    public static func register() {
        // are we already registered?
        let registration = UserDefaults.standard.value(forKey: "registration") as? [String:String]
        if registration == nil || registration?["userId"] != TRACSClient.userid || registration?["deviceToken"] != deviceToken {
            // do we have enough information to register?
            if TRACSClient.userid.isEmpty || deviceToken.isEmpty {
                return
            }
            
            // register with the integration server
            let reg = ["app_id": "tracs_ios", "user_id": TRACSClient.userid, "device_id":deviceToken]
            Utils.post(url: registrationurl, params: reg, completion: { (data, success) in
                NSLog("attempted registration with integration server")
                if success {
                    // save the registration details so that we don't have to do this often
                    UserDefaults.standard.set(["userId":TRACSClient.userid, "deviceToken":deviceToken], forKey: "registration")
                }
            })
        }
    }
    
    public static func unregister() {
        TRACSClient.userid = ""
        UserDefaults.standard.removeObject(forKey: "registration")
        if !deviceToken.isEmpty {
            Utils.delete(url: registrationurl, params: ["device_id":deviceToken], completion: { (data, success) in
                // not sure if we need to do anything here
            })
        }
    }
}
