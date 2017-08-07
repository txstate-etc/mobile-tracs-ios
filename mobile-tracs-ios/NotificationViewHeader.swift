//
//  NotificationGroupCell.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/25/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class NotificationViewHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerSwitch: HeaderSwitch!
    @IBOutlet weak var viewContainer: UIView!

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        headerLabel = UILabel()
        viewContainer = UIView()
        headerSwitch = HeaderSwitch()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
