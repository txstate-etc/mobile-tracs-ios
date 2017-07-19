//
//  LoginTextField.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/12/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

@IBDesignable
class LoginTextField: UITextField {
    //MARK: Properties
    @IBInspectable var cornerRadius: CGFloat = 10.0 {
        didSet {
            updateCornerRadius()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = UIColor(white: 231 / 255, alpha: 1).cgColor
        self.layer.borderWidth = 1
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: (self.layer.bounds.height / 4))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    func updateCornerRadius() {
        self.layer.cornerRadius = cornerRadius
    }
}
