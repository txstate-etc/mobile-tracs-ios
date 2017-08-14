//
//  LoginLogoImage.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/12/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

@IBDesignable
class LoginLogoImage: UIImageView {
    //MARK: Properties
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            updateCornerRadius()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = cornerRadius
    }
    
    func updateCornerRadius() {
        self.layer.cornerRadius = cornerRadius
    }
}
