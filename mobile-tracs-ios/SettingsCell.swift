//
//  SettingsCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class SettingsCell: UITableViewCell {
    @IBOutlet var toggle: UISwitch!
    @IBOutlet var title: UILabel!
    
    var filter_key: String = ""
    var filter_value: String = ""
    var targetset = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
