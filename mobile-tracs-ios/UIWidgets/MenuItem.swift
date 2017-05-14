//
//  MenuItem.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/13/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class MenuItem : Equatable {
    static let settings = MenuItem(label: "Settings", icon: .gear)
    static let home = MenuItem(label: "Home", icon: .home)
    static let txstate = MenuItem(label: "Main App", icon: .caretUp)
    static let feedback = MenuItem(label: "Feedback", icon: .envelopeO)
    
    var label:String
    var icon:FontAwesome
    
    private init(label:String, icon:FontAwesome) {
        self.label = label
        self.icon = icon
    }
    
    static func ==(left:MenuItem, right:MenuItem) -> Bool {
        return left.label == right.label
    }
}
