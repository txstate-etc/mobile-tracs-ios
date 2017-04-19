//
//  Analytics.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/13/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class Analytics {
    static let tracker = Utils.isSimulator() ? nil : GAI.sharedInstance().tracker(withTrackingId: Secrets.shared.analyticsid)
    
    static func viewWillAppear(_ name:String) {
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: name)
            tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject:AnyObject])
        }
    }
    
    static func linkClick(_ url:String) {
        event(category: "Link", action: "click", label: url, value: nil)
    }
    
    static func event(category:String, action:String, label:String, value:NSNumber?) {
        if let tracker = tracker {
            tracker.send(GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value).build() as [NSObject:AnyObject])
        }
    }
}
