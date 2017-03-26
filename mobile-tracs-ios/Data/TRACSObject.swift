//
//  TRACSObject.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

protocol TRACSObject {
    var id:String { get set }
    var site:Site? { get set }
    func titleForTable()->String
    func getType()->String
    func getUrl()->String
}

extension TRACSObject {
    func tableSubtitle()->String {
        return site?.title ?? ""
    }
}

class TRACSObjectBase {
    var id = ""
    var site:Site?
    
    init(dict:[String:Any]) {
        id = dict["id"] as? String ?? ""
    }
}
