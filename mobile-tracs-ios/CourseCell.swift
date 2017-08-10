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
    @IBOutlet var cellContent: UIView!
    weak var delegate:CourseCellDelegate?
    var site:Site? {
        didSet {
            updateUI(site: site)
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
    
    func updateUI(site: Site?) {
        if site == nil {
            return;
        }
        if site?.title == "My Workspace" {
            //Set up workspace here
        }
        titleLabel.text = site?.title
        let isCourse = isCourseSite(site: site)
        let primaryColor = isCourse ? SiteColor.coursePrimary : SiteColor.projectPrimary
        let secondaryColor = isCourse ? SiteColor.courseSecondary : SiteColor.projectSecondary
        let textColor = isCourse ? SiteColor.courseText : SiteColor.projectText
        
        setupCellContent(background: primaryColor, contentView: cellContent)
        setupCellIcons(site: site!, iconColor: secondaryColor, toolbar: toolbar)
        setupCellLabel(text: textColor, background: primaryColor, label: titleLabel)
    }
    
    func setupCellContent(background: UIColor, contentView: UIView) {
        contentView.backgroundColor = background
    }
    
    func setupCellIcons(site: Site, iconColor: UIColor, toolbar: UIToolbar) {
        if site.hasdiscussions {
            toolbar.items?[1] = Utils.fontAwesomeBadgedBarButtonItem(color: iconColor, badgecount: 0, icon: Discussion.icon, target: self, action: #selector(discussionPressed))
        } else {
            toolbar.items?[1] = Utils.fontAwesomeBadgedBarButtonItem(color: UIColor(white: 1, alpha: 0), badgecount: 0, icon: Discussion.icon, target: self, action: #selector(discussionPressed))
            (toolbar.items?[1].customView as! UIButton).isUserInteractionEnabled = false
        }
        toolbar.items?[3] = Utils.fontAwesomeBadgedBarButtonItem(color: iconColor, badgecount: (site.unseenCount), icon: .dashboard, target: self, action: #selector(dashboardPressed))
    }
    
    func setupCellLabel(text: UIColor, background: UIColor, label: UILabel) {
        label.backgroundColor = background
        label.textColor = text
    }
    
    func isCourseSite(site: Site?) -> Bool {
        if let site = site {
            return site.coursesite
        }
        return false
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
