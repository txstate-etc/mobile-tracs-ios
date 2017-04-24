//
//  NotificationCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 4/23/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

protocol NotificationCellDelegate {
    func cellSwipedLeft(_ cell:NotificationCell, notify:Notification)
}

class NotificationCell: UITableViewCell {
    var delegate:NotificationCellDelegate?
    var notify:Notification?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let gest = UISwipeGestureRecognizer(target: self, action: #selector(cellSwipedLeft(gest:)))
        gest.direction = .left
        self.addGestureRecognizer(gest)
    }
    
    func cellSwipedLeft(gest:UIGestureRecognizer) {
        if let del = delegate, let noti = notify {
            del.cellSwipedLeft(self, notify: noti)
        }
    }
    
}
