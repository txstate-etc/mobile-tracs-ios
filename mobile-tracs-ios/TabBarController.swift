//
//  TabBarController.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 8/2/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

class TabBarController : UITabBarController {
    @IBOutlet var tracsTabBar: UITabBar!
    override func viewDidLoad() {
        super.viewDidLoad()
        for barItem in tracsTabBar.items! {
            let title = barItem.title!
            switch title {
            case "Sites":
                barItem.image = UIImage.fontAwesomeIcon(name: .university, textColor: Utils.darkred, size: CGSize(width:28, height: 28))
                break
            case "Announcements":
                barItem.image = UIImage.fontAwesomeIcon(name: .bullhorn, textColor: Utils.darkred, size: CGSize(width:28, height: 28))
                break
            case "Settings":
                barItem.image = UIImage.fontAwesomeIcon(name: .cogs, textColor: Utils.darkred, size: CGSize(width:28, height: 28))
                break
            default:
                break
            }
        }
    }
}
