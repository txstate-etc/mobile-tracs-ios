//
//  TabBarController.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 8/2/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

class TabBarController : UITabBarController {
    @IBOutlet var tracsTabBar: UITabBar!
    
    let color = UIColor(red: 188/255, green: 162/255, blue: 164/255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for barItem in tracsTabBar.items! {
            let title = barItem.title!
            switch title {
            case "All Sites":
                barItem.image = UIImage.fontAwesomeIcon(name: .list, textColor: color, size: CGSize(width: 36, height: 36))
                break
            case "Announcements":
                barItem.image = UIImage.fontAwesomeIcon(name: .bullhorn, textColor: color, size: CGSize(width: 36, height: 36))
                break
            case "Settings":
                barItem.image = UIImage.fontAwesomeIcon(name: .cog, textColor: color, size: CGSize(width: 36, height: 36))
                break
            default:
                break
            }
        }
        self.selectedIndex = 1
        self.tabBar.tintColor = UIColor.init(white: 1, alpha: 1)
    }
    
    open func updateAnnounceCount(count: Int) {
        self.tabBar.items?[0].badgeValue = count > 0 ? String(count) : nil
    }
}
