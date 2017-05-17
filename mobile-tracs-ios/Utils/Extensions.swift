//
//  Extensions.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation
import UIKit

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension UINavigationBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.size.width, height: 50.0)
    }
}
