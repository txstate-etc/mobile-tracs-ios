//
//  AdvisoryLabel.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

@IBDesignable
class AdvisoryLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}
