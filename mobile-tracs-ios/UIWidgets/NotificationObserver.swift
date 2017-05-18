//
//  NotificationObserver.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

protocol NotificationObserver {
    func incomingNotification(badgeCount:Int?, message:String?)
}
