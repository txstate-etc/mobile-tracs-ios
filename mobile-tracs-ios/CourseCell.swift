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
    @IBOutlet var rightChevron: UIImageView!
    @IBOutlet var siteWord: UILabel!
    weak var delegate:CourseCellDelegate?
    var badgeCounts: [String: Int] = [:]
    var site:Site? {
        didSet {
            updateUI(site: site, badgeCounts: badgeCounts)
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
    
    func updateUI(site: Site?, badgeCounts: [String: Int]) {
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
        setupCellIcons(site: site!, iconColor: secondaryColor, badgeCounts: badgeCounts, toolbar: toolbar)
        setupCellLabel(text: textColor, background: primaryColor, label: titleLabel)
    }
    
    func setupCellContent(background: UIColor, contentView: UIView) {
        contentView.backgroundColor = background
    }
    
    func setupCellIcons(site: Site, iconColor: UIColor, badgeCounts: [String: Int], toolbar: UIToolbar) {
        if site.hasdiscussions {
            let badge = badgeCounts["discussion"] ?? 0
            toolbar.items?[1] = Utils.fontAwesomeTitledBarButtonItem(color: iconColor, icon: Discussion.icon, title: "Forums", badgecount: badge, target: self, action: #selector(discussionPressed))
        } else {
            toolbar.items?[1] = Utils.fontAwesomeTitledBarButtonItem(color: UIColor(white: 1, alpha: 0), icon: Discussion.icon, title: "Forums", badgecount: 0, target: self, action: #selector(discussionPressed))
            (toolbar.items?[1].customView as! UIButton).isUserInteractionEnabled = false
        }
        let badge = (badgeCounts["announcement"] ?? 0) + (badgeCounts["discussion"] ?? 0)
        toolbar.items?[3] = Utils.fontAwesomeTitledBarButtonItem(color: iconColor, icon: .dashboard, title: "Dashboard", badgecount: badge, target: self, action: #selector(dashboardPressed))
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
