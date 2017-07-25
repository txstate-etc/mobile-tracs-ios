//
//  NotificationViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotificationObserver {
    @IBOutlet var tableView: UITableView!
    var notifications: [Notification] = []
    var site:Site?
    var announcementCount: Int = 0
    var discussionCount: Int = 0
    enum Section: String {
        case Announcements = "announcement"
        case Discussions = "discussion"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName:"NotificationCell", bundle: nil), forCellReuseIdentifier: "notification")
        tableView.register(UINib(nibName:"NotificationViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "sectionlabel")
        //navigationItem.rightBarButtonItem = Utils.fontAwesomeTitledBarButtonItem(color: (navigationController?.navigationBar.tintColor)!, icon: .timesCircle, title: "Clear All", textStyle: .body, target: self, action: #selector(clearAllPressed))
        NotificationCenter.default.addObserver(self, selector: #selector(loadOnAppear), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOnAppear), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadOnAppear()
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return announcementCount
        case 1:
            return discussionCount
        default:
            return notifications.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionlabel") as! NotificationViewHeader
        switch section {
        case 0:
            header.headerLabel.text = "Announcements"
            header.headerSwitch.addTarget(self, action: #selector(getSetting), for: UIControlEvents.touchUpInside)
            break
        case 1:
            header.headerLabel.text = "Discussions"
            break
        default:
            break
        }
        return header
    }

    func getSetting() {
        print ("Toggled")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
        switch indexPath.section {
        case 0:
            let notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
            cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
        case 1:
            let notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
            cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
            break
        default:
            break
        }
        return cell
    }
    
    func buildCell(cell: NotificationCell, indexPath: IndexPath, notify: Notification?) -> NotificationCell {
        if let tracsobj = notify?.object {
            cell.isRead = (notify?.isRead())!
            cell.iView.image = UIImage.fontAwesomeIcon(name: tracsobj.getIcon(), textColor: Utils.nearblack, size:CGSize(width: 200, height: 200))
            cell.titleLabel.text = tracsobj.tableTitle()
            cell.titleLabel.font = (notify?.isRead())! ? UIFont.preferredFont(forTextStyle: .body) : Utils.boldPreferredFont(style: .body)
            cell.subtitleLabel.text = tracsobj.tableSubtitle()
            cell.subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            if !tracsobj.getUrl().isEmpty {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: .body).pointSize * 2.8
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [UITableViewRowAction(style: .default, title: "Dismiss", handler: { (action, indexPath) in
            let n = self.notifications[indexPath.row]
            IntegrationClient.markNotificationCleared(n) { (success) in
                DispatchQueue.main.async {
                    if success {
                        self.notifications.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        Analytics.event(category: "Notification", action: "cleared", label: n.object_type ?? "", value: nil)
                    }
                }
            }
        })]
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notify = notifications[indexPath.row]
        if let tracsobj = notify.object {
            if let url = URL(string: tracsobj.getUrl()) {
                IntegrationClient.markNotificationRead(notify, completion: { (success) in
                })
                Analytics.event(category: "Notification", action: "click", label: notifications[indexPath.row].object_type ?? "", value: nil)
                let wvc = WebViewController(urlToLoad: url.absoluteString)
                navigationController?.pushViewController(wvc!, animated: true)
            }
        }
    }
    
    // MARK: - More functions
    
    func loadOnAppear() {
        Analytics.viewWillAppear("Notifications")
        loadNotifications(true)
    }
    
    func loadNotifications(_ showactivity:Bool) {
        if showactivity { Utils.showActivity(view) }
        TRACSClient.loginIfNecessary { (loggedin) in
            if loggedin {
                IntegrationClient.getNotifications { (notifications) in
                    self.discussionCount = 0
                    self.announcementCount = 0
                    if let notis = notifications {
                        let unseen = notis.filter({ (n) -> Bool in
                            var desiredSite: Bool
                            if let site = self.site {
                                desiredSite = n.site_id == site.id
                            } else {
                                desiredSite = true
                            }
                            return !n.seen && desiredSite
                        })
                        IntegrationClient.markNotificationsSeen(unseen, completion: { (success) in
                            DispatchQueue.main.async {
                                UIApplication.shared.applicationIconBadgeNumber = 0
                                self.notifications = notis.filter({ (n) -> Bool in
                                    var shouldBeDisplayed = true
                                    if let site = self.site {
                                        shouldBeDisplayed = n.site_id == site.id
                                    }
                                    if (shouldBeDisplayed) {
                                        if let type = n.object_type {
                                            switch type {
                                            case Section.Announcements.rawValue:
                                                self.announcementCount += 1
                                            case Section.Discussions.rawValue:
                                                self.discussionCount += 1
                                            default:
                                                break
                                            }
                                        }
                                    }
                                    return shouldBeDisplayed
                                })
                                self.tableView.reloadData()
                                Utils.hideActivity()
                            }
                        })
                    }
                }
            } else {
                (UIApplication.shared.delegate as! AppDelegate).reloadEverything()
            }
        }
    }
    
    func getNotification(notificationType: String, position: Int) -> Notification? {
        var totalFound = 0
        for notif in notifications {
            if notif.object_type == notificationType {
                if totalFound == position {
                    return notif
                }
                totalFound += 1
            }
        }
        return nil
    }
    
    func countTypes(notificationType: String) -> Int {
        var count = 0
        
        if self.notifications.count == 0 {
            return count
        }
        for notif in self.notifications {
            if notif.object_type == notificationType {
                count += 1
            }
        }
        return count
    }
    
    func clearAllPressed() {
        IntegrationClient.markAllNotificationsCleared(notifications) { (success) in
            if success {
                DispatchQueue.main.async {
                    self.notifications = []
                    self.tableView.reloadData()
                    Analytics.event(category: "Notification", action: "cleared", label: "all", value: nil)
                }
            }
        }
    }
    
    func incomingNotification(badgeCount: Int?, message: String?) {
        loadNotifications(false)
    }
}
