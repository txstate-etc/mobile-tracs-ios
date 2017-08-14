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
    @IBInspectable var cornerRadius: CGFloat = 0.0 {
        didSet {
            updateCornerRadius()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let borderLine = UIView()
        
        borderLine.frame = CGRect(x: 0, y: self.frame.size.height - 1, width: self.frame.size.width, height: 1)
        borderLine.backgroundColor = LoginColor.inputUnderline
        self.addSubview(borderLine)
        self.layer.cornerRadius = cornerRadius
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 0, dy: 8)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
    
    func updateCornerRadius() {
        self.layer.cornerRadius = cornerRadius
    }
}
