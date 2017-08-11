//
//  CardView.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 8/2/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

@IBDesignable
class CardView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 0
    @IBInspectable var shadowOffsetWidth: Int = 1
    @IBInspectable var shadowOffsetHeight: Int = 1
    @IBInspectable var shadowColor: UIColor? = UIColor.black
    @IBInspectable var shadowOpacity: Float = 0.75
    
    override func layoutSubviews() {
        layer.cornerRadius = cornerRadius
        let rect: CGRect = layer.visibleRect.insetBy(dx: 1, dy: 1)
        let shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        layer.shadowColor = shadowColor?.cgColor
        layer.shadowOffset = CGSize(width: shadowOffsetWidth, height: shadowOffsetHeight)
        layer.shadowOpacity = shadowOpacity
        layer.shadowPath = shadowPath.cgPath
        layer.shadowRadius = 1
    }
}
