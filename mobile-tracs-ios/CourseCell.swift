//
//  CourseCell.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

protocol CourseCellDelegate:class {
    func discussionPressed(site:Site)
    func dashboardPressed(site:Site)
}

class CourseCell: UITableViewCell {
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var toolbar:UIToolbar!
    weak var delegate:CourseCellDelegate?
    var site:Site? {
        didSet {
            updateUI()
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        } else {
            toolbar.items?[1] = Utils.fontAwesomeBadgedBarButtonItem(color: UIColor(white: 1, alpha: 0), badgecount: 0, icon: Discussion.icon, target: self, action: #selector(discussionPressed))
            (toolbar.items?[1].customView as! UIButton).isUserInteractionEnabled = false
        }
        toolbar.items?[3] = Utils.fontAwesomeBadgedBarButtonItem(color: Utils.darkgray, badgecount: (site?.unseenCount)!, icon: .dashboard, target: self, action: #selector(dashboardPressed))
    }
    
    func discussionPressed() {
        if let site = site {
            delegate?.discussionPressed(site: site)
        }
    }
    
    func dashboardPressed() {
        if let site = site {
            delegate?.dashboardPressed(site: site)
        }
    }
}
