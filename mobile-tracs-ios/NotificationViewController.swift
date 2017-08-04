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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName:"NotificationViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "sectionlabel")
        if site == nil {
            self.title = "Announcements"
        } else {
            self.title = "Notifications"
        }
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
        var sections: Int
        if let site = site {
            sections = 0
            if site.hasannouncements { sections += 1 }
            if site.hasdiscussions { sections += 1 }
        } else {
            sections = 1
        }

        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return announcementCount > 0 ? announcementCount : 1
        case 1:
            return discussionCount > 0 ? discussionCount : 1
        default:
            return notifications.count > 0 ? notifications.count : 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var headerSize: CGFloat = 45
        if site == nil {
            headerSize = CGFloat.leastNonzeroMagnitude
        }
        return headerSize
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
        if let site = site {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionlabel") as! NotificationViewHeader
            header.headerSwitch.site = site
            
            header.headerSwitch.addTarget(self, action: #selector(toggleSetting(sender:)), for: UIControlEvents.touchUpInside)
            switch section {
            case 0:
                header.headerLabel.text = "Announcements"
                header.headerSwitch.notificationType = Section.Announcements.rawValue
                break
            case 1:
                header.headerLabel.text = "Forums"
                header.headerSwitch.notificationType = Section.Discussions.rawValue
                break
            default:
                break
            }
            
            let setting = makeSettingForSwitch(toggleSwitch: header.headerSwitch)
            let settings = IntegrationClient.getRegistration().settings
            let settingIsDisabled = settings!.entryIsDisabled(SettingsEntry(dict: setting))
            header.headerSwitch.isOn = !settingIsDisabled
            return header
        }
        return nil
    }

    func toggleSetting(sender: HeaderSwitch) {
        
        let newSetting = makeSettingForSwitch(toggleSwitch: sender)
        
        let settings = IntegrationClient.getRegistration().settings
        if !sender.isOn {
            settings?.disableEntry(SettingsEntry(dict: newSetting))
        } else {
            settings?.enableEntry(SettingsEntry(dict: newSetting))
        }
        IntegrationClient.saveSettings(settings!, completion: { (success) in
            Analytics.event(category: "Filter", action: sender.isOn ? "allow" : "block", label: "\(sender.site?.id ?? "") - \(sender.notificationType ?? "")", value: nil)
            NSLog("\(sender.notificationType ?? "") \(sender.isOn ? "enabled" : "disabled") for \(sender.site?.title ?? "")")
            self.loadNotifications(false)
        })
        
    }
    
    func makeSettingForSwitch(toggleSwitch: HeaderSwitch) -> [String: [String: String]] {
        var newSetting = [
            "keys": [
                "object_type": toggleSwitch.notificationType ?? ""
            ]
        ]
        if let siteID = toggleSwitch.site?.id {
            newSetting["other_keys"] = ["site_id": siteID]
        }
        return newSetting
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
        switch indexPath.section {
        case 0:
            if announcementCount > 0 {
                let notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
            } else {
                cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
            }
        case 1:
            if discussionCount > 0 {
                let notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
            } else {
                cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
            }
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
            cell.subtitleLabel.text = getSubtitleFromNotification(notif: notify!)
            cell.subtitleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            if !tracsobj.getUrl().isEmpty {
                cell.accessoryType = .disclosureIndicator
            }
            cell.isUserInteractionEnabled = true
        } else {
            var titleLabel: String = ""
            switch indexPath.section {
            case 0:
                if announcementCount == 0 {
                    titleLabel = "No new announcements"
                }
            case 1:
                if discussionCount == 0 {
                    titleLabel = "No new forum posts"
                }
            default:
                titleLabel = ""
            }
            cell.isRead = true
            cell.iView.image = nil
            cell.titleLabel.text = titleLabel
            cell.subtitleLabel.text = ""
            cell.isUserInteractionEnabled = false
        }
        return cell
    }
    
    func getSubtitleFromNotification(notif: Notification) -> String {
        if let type = notif.object_type {
            switch (type) {
            case "announcement":
                let ann = notif.object as! Announcement
                return ann.subtitle
            case "discussion":
                let disc = notif.object as! Discussion
                return disc.subtitle
            default:
                break
            }
        }
        return ""
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
                        tableView.beginUpdates()
                        let index = self.convertIndex(indexPath: indexPath)
                        self.notifications.remove(at: index)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                        self.tableView.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
                        tableView.endUpdates()
                        //TODO: Fix this right here to delete and not add a phantom row
                        self.loadNotifications(true)
                        Analytics.event(category: "Notification", action: "cleared", label: n.object_type ?? "", value: nil)
                    }
                }
            }
        })]
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var notify: Notification?
        switch indexPath.section {
        case 0:
            if announcementCount == 0 {
                return
            }
            notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
        case 1:
            if discussionCount == 0 {
                return
            }
            notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
        default:
            break
        }
        if let tracsobj = notify?.object {
            if let url = URL(string: tracsobj.getUrl()) {
                IntegrationClient.markNotificationRead(notify!, completion: { (success) in
                })
                Analytics.event(category: "Notification", action: "click", label: notifications[indexPath.row].object_type ?? "", value: nil)
                let wvStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
                let wvController = wvStoryBoard.instantiateViewController(withIdentifier: "TracsWebView")
                (wvController as! WebViewController).urlToLoad = url.absoluteString
                navigationController?.pushViewController(wvController, animated: true)
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
                                    } else {
                                        shouldBeDisplayed = n.object_type == Section.Announcements.rawValue
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
    
    func convertIndex(indexPath: IndexPath) -> Int {
        var notificationType: String = ""
        var returnIndex = -1
        switch indexPath.section {
        case 0:
            notificationType = Section.Announcements.rawValue
        case 1:
            notificationType = Section.Discussions.rawValue
        default:
            break
        }
        
        var totalFound = 0
        for notif in notifications {
            if notif.object_type == notificationType {
                if totalFound == indexPath.row {
                    returnIndex = notifications.index(of: notif)!
                    break
                }
                totalFound += 1
            }
        }
        return returnIndex
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
