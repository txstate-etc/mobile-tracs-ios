//
//  CourseCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class CourseCell: UITableViewCell {
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var toolbar:UIToolbar!
    var site:Site? {
        didSet {
            updateUI()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI() {
        titleLabel.text = site?.title
        if site?.hasdiscussions ?? false {
            toolbar.items?[1] = Utils.fontAwesomeBadgedBarButtonItem(color: Utils.darkgray, badgecount: 0, icon: Discussion.icon, target: self, action: #selector(discussionPressed))
        }
    }
    
    func discussionPressed() {
        
    }
}
