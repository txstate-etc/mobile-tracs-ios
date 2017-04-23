//
//  Cacheable.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

protocol Cacheable : NSCoding {
    var id:String { get }
    var created_at:Date { get }
}

extension Cacheable {
    func shouldRefresh()->Bool {
        return Utils.date(created_at, isOlderThan: 5, units: .minute)
    }
    func isExpired()->Bool {
        return Utils.date(created_at, isOlderThan: 2, units: .day)
    }
}
