//
//  WorkspaceButton.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 8/11/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

class WorkspaceButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        centerTitleLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        centerTitleLabel()
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        
        return CGRect(x: 0, y: imageRect.maxY * 0.85, width: contentRect.width, height: titleRect.height)
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageRect = super.imageRect(forContentRect: contentRect)
        
        return CGRect(x: (contentRect.width - imageRect.width)/2, y: (contentRect.height - imageRect.height)/2, width: imageRect.height, height: imageRect.width)
    }
    
    private func centerTitleLabel() {
        self.titleLabel?.textAlignment = .center
        let fontSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 0.60
        self.titleLabel?.font = self.titleLabel?.font.withSize(fontSize)
    }
}
