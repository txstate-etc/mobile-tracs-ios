//
//  CourseCell.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 8/2/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class WorkspaceCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cellContent: UIView!
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
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateUI(site: Site?) {
        if site == nil {
            return;
        }
        titleLabel.text = site?.title
        let primaryColor = SiteColor.workspacePrimary
        let textColor = SiteColor.workspaceText
        
        setupCellContent(background: primaryColor, contentView: cellContent)
        setupCellLabel(text: textColor, background: primaryColor, label: titleLabel)
    }
    
    func setupCellContent(background: UIColor, contentView: UIView) {
        contentView.backgroundColor = background
    }
    
    func setupCellLabel(text: UIColor, background: UIColor, label: UILabel) {
        label.backgroundColor = background
        label.textColor = text
    }
}
