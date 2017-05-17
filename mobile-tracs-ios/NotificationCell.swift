//
//  NotificationCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

protocol NotificationCellDelegate {
}

class NotificationCell: UITableViewCell {
    var delegate:NotificationCellDelegate?
    var notify:Notification?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
