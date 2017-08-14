//
//  LoginButton.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/12/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

@IBDesignable
class LoginButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 10.0 {
        didSet {
            updateCornerRadius()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = LoginColor.loginButton
        self.tintColor = UIColor.white
    }
    
    func updateCornerRadius() {
        self.layer.cornerRadius = cornerRadius
    }
}
