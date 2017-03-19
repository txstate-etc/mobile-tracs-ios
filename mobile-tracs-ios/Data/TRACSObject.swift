//
//  TRACSObject.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class TRACSObject {
    public var id: String = ""

    init(dict:[String:Any]) {
        id = dict["id"] as! String
    }
}
