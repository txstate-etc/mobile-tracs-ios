//
//  NotificationCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
    @IBOutlet var unreadBar:UIView!
    @IBOutlet var iViewContainer: UIView!
    @IBOutlet var iView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    var lastheight = CGFloat(0.0)
    var isRead:Bool {
        didSet {
            iViewContainer.backgroundColor = isRead ? nil : Utils.gray
        }
    }
        
    required init?(coder aDecoder: NSCoder) {
        isRead = false
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let h = iViewContainer.frame.height
        if h != lastheight {
            lastheight = h
            iViewContainer.layer.cornerRadius = h / 2.0
        }
    }
}
