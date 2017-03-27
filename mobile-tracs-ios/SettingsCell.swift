//
//  SettingsCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

protocol SettingsCellDelegate {
    func cellDidToggle(_ cell:SettingsCell, toggle:UISwitch)
}

class SettingsCell: UITableViewCell {
    @IBOutlet var toggle: UISwitch!
    @IBOutlet var title: UILabel!
    
    var entry:SettingsEntry?
    var delegate:SettingsCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        toggle.addTarget(self, action: #selector(relayCallback(sender:)), for: .valueChanged)
    }
    
    func relayCallback(sender: UISwitch) {
        if delegate != nil { delegate!.cellDidToggle(self, toggle: toggle) }
    }
}
