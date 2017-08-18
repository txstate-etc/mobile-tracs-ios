//
//  NotificationViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var courseDescription: UILabel!
    @IBOutlet var contactLastname: UILabel!
    @IBOutlet weak var contactEmail: UILabel!
    
    let NO_FORUM_POSTS = "No new forum posts"
    let NO_ANNOUNCEMENTS = "No new announcements"
    let NO_TOOLS_ENABLED = "No new notifications"
    
    var notifications: [Notification] = []
    var site:Site?
    var announcementCount: Int = 0
    var discussionCount: Int = 0
    var announcementHeader: NotificationViewHeader?
    var discussionHeader: NotificationViewHeader?
    enum Section: String {
        case Announcements = "announcement"
        case Discussions = "discussion"
    }
    enum Style: String {
        case Dashboard = "dashboard"
        case Discussions = "dicussions"
    }
    var announcementSection: Int?
    var discussionSection: Int?
    var viewStyle: Style?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName:"NotificationViewHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "sectionlabel")
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: NSNotification.Name(rawValue: ObservableEvent.PUSH_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOnAppear), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadOnAppear), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        if let site = site {
            if site.hasannouncements {
                announcementSection = 0
                if site.hasdiscussions {
                    discussionSection = 1
                }
            } else {
                if site.hasdiscussions {
                    discussionSection = 0
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let viewStyle = viewStyle {
            if let site = site {
                let fullName = site.contactLast.isEmpty ? "Contact info not found" : "\(site.contactFull),"
                if site.contactEmail.isEmpty {
                    contactEmail.isHidden = true
                } else {
                    contactEmail.text = site.contactEmail
                    let emailTap = UITapGestureRecognizer(target: self, action: #selector(NotificationViewController.openEmailClient))
                    contactEmail.addGestureRecognizer(emailTap)
                    contactEmail.isUserInteractionEnabled = true
                }
                
                contactLastname.text = fullName
            }
            switch viewStyle {
            case .Discussions:
                self.title = "Forums"
                break
            case .Dashboard:
                self.title = "Notifications"
                break
            }
        } else {
            self.title = "Announcements"
            removeHeaderView(headerView: headerView)
        }
        headerLabel.text = site?.title
        loadOnAppear()
    }
    
    func openEmailClient() {
        let email = contactEmail.text ?? ""
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.openURL(url)
        }
        
    }
    
    func removeHeaderView(headerView: UIView) {
        var rect = headerView.frame
        rect.size.height = 0
        headerView.frame = rect
        headerView.removeFromSuperview()
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections: Int
        if let site = site, let viewStyle = viewStyle {
            sections = 0
            if viewStyle == Style.Discussions {
                return 1
            }
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
            var sectionCount: Int
            if let viewStyle = viewStyle {
                switch viewStyle {
                case .Discussions: //Section 0 is discussions
                    sectionCount = discussionCount > 0 ? discussionCount : 1
                case .Dashboard:
                    if announcementSection == 0 {
                        sectionCount = announcementCount > 0 ? announcementCount : 1
                    } else if discussionSection == 0 {
                        sectionCount = discussionCount > 0 ? discussionCount : 1
                    } else {
                        sectionCount = 1
                    }
                }
            } else {
                sectionCount = announcementCount > 0 ? announcementCount : 1
            }
            return sectionCount
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
        if let viewStyle = viewStyle, viewStyle == Style.Discussions {
            headerSize = CGFloat.leastNonzeroMagnitude
        }
        return headerSize
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    
        if site != nil, let viewStyle = viewStyle {
            if viewStyle == Style.Discussions { return nil }
            let settings = IntegrationClient.getRegistration().settings
            switch section {
            case 0:
                if announcementSection == 0 {
                    if announcementHeader == nil {
                        announcementHeader = initialHeaderSetup(type: Section.Announcements)
                    }
                    let setting = makeSettingForSwitch(toggleSwitch: (announcementHeader?.headerSwitch)!)
                    let settingIsDisabled = settings!.entryIsDisabled(SettingsEntry(dict: setting))
                    announcementHeader?.headerSwitch.isOn = !settingIsDisabled
                    return announcementHeader
                } else {
                    if discussionHeader == nil {
                        discussionHeader = initialHeaderSetup(type: Section.Discussions)
                    }
                    let setting = makeSettingForSwitch(toggleSwitch: (discussionHeader?.headerSwitch)!)
                    let settingIsDisabled = settings!.entryIsDisabled(SettingsEntry(dict: setting))
                    discussionHeader?.headerSwitch.isOn = !settingIsDisabled
                    return discussionHeader
                }
                
            case 1:
                if discussionHeader == nil {
                    discussionHeader = initialHeaderSetup(type: Section.Discussions)
                }
                let setting = makeSettingForSwitch(toggleSwitch: (discussionHeader?.headerSwitch)!)
                let settingIsDisabled = settings!.entryIsDisabled(SettingsEntry(dict: setting))
                discussionHeader?.headerSwitch.isOn = !settingIsDisabled
                return discussionHeader
            default:
                break
            }
        }
        return nil
    }
    
    func initialHeaderSetup(type: Section) -> NotificationViewHeader {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionlabel") as? NotificationViewHeader
        header?.headerSwitch.site = site
        header?.headerSwitch.addTarget(self, action: #selector(toggleSetting(sender:)), for: UIControlEvents.touchUpInside)
        
        switch type {
        case .Announcements:
            header?.headerLabel.text = "Announcements"
            header?.headerSwitch.notificationType = Section.Announcements.rawValue
            break
        case .Discussions:
            header?.headerLabel.text = "Forums"
            header?.headerSwitch.notificationType = Section.Discussions.rawValue
            break
        }
        return header!
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
        var cell: NotificationCell
        switch indexPath.section {
        case 0:
            if let viewStyle = viewStyle { //Not in Announcements screen
                cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
                if viewStyle == Style.Discussions { //In Discussion screen
                    if discussionCount > 0 { //Discussions are available
                        let notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                        cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
                    } else { //Nothing to display
                        cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
                    }
                }
                if viewStyle == Style.Dashboard { //In Dashboard screen
                    if announcementSection == 0 { //This section is for announcements
                        if announcementCount > 0 { //Announcements are available
                            let notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                            cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
                        } else { //Nothing to display
                            cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
                        }
                    } else if discussionSection == 0 { //This section must be for discussions
                        if discussionCount > 0 { //Discussions are available
                            let notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                            cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
                        } else {
                            cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
                        }
                    } else { //The site has no notification tools
                        cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
                    }
                }
            } else { //In All Announcements screen
                cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
                if announcementCount > 0 { //Announcements are available
                    let notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                    cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
                    
                } else { //Nothing to display
                    cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
                }
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
            if discussionCount > 0 {
                let notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                cell = buildCell(cell: cell, indexPath: indexPath, notify: notify)
            } else {
                cell = buildCell(cell: cell, indexPath: indexPath, notify: nil)
            }
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
            break
        }
        return cell
    }
    
    func buildCell(cell: NotificationCell, indexPath: IndexPath, notify: Notification?) -> NotificationCell {
        if let tracsobj = notify?.object {
            cell.isRead = (notify?.isRead())!
            let imageColor = cell.isRead ? Utils.readIcon : Utils.unreadIcon
            cell.iView.image = UIImage.fontAwesomeIcon(name: tracsobj.getIcon(), textColor: imageColor, size:CGSize(width: 200, height: 200))
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
                if let viewStyle = viewStyle {
                    if viewStyle == Style.Discussions {
                        if discussionCount == 0 {
                            titleLabel = NO_FORUM_POSTS
                        }
                    } else {
                        if announcementCount == 0 && announcementSection == 0 {
                            titleLabel = NO_ANNOUNCEMENTS
                        } else if discussionCount == 0 && discussionSection == 0 {
                            titleLabel = NO_FORUM_POSTS
                        } else {
                            titleLabel = NO_TOOLS_ENABLED
                        }
                    }
                } else {
                    if announcementCount == 0 {
                        titleLabel = NO_ANNOUNCEMENTS
                    }
                }
            case 1:
                if discussionCount == 0 {
                    titleLabel = NO_FORUM_POSTS
                }
            default:
                titleLabel = NO_TOOLS_ENABLED
            }
            cell.isRead = true
            cell.iView.image = nil
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
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
                return notif.object?.site?.title ?? ""
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
            var n: Notification?
            switch indexPath.section {
            case 0:
                if let viewStyle = self.viewStyle {
                    switch viewStyle {
                    case .Discussions:
                        n = self.getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                        break
                    case .Dashboard:
                        if self.announcementSection == 0 {
                            n = self.getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                        } else if self.discussionSection == 0 {
                            n = self.getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                        } else {
                            n = self.getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                        }
                        break
                    }
                } else {
                    n = self.getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                }
                break
            case 1:
                n = self.getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                break
            default:
                n = nil
                break
            }
            if let n = n {
                IntegrationClient.markNotificationCleared(n) { (success) in
                    DispatchQueue.main.async {
                        if success {
                            tableView.beginUpdates()
                            let index = self.convertIndex(indexPath: indexPath)
                            self.notifications.remove(at: index)
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            self.tableView.reloadSections([indexPath.section], with: UITableViewRowAnimation.automatic)
                            tableView.endUpdates()
                            self.loadNotifications(true)
                            Analytics.event(category: "Notification", action: "cleared", label: n.object_type ?? "", value: nil)
                        }
                    }
                }
            }
        })]
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var notify: Notification?
        switch indexPath.section {
        case 0:
            if let style = viewStyle {
                switch style {
                case .Dashboard:
                    if announcementSection == 0 {
                        if announcementCount == 0 {
                            return
                        }
                        notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
                    } else if discussionSection == 0 {
                        if discussionCount == 0 {
                            return
                        }
                        notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                    } else {
                        return
                    }
                break
                case .Discussions:
                    if discussionCount == 0 {
                        return
                    }
                    notify = getNotification(notificationType: Section.Discussions.rawValue, position: indexPath.row)
                    break
                }
            } else {
                if announcementCount == 0 {
                    return
                }
                notify = getNotification(notificationType: Section.Announcements.rawValue, position: indexPath.row)
            }
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
                IntegrationClient.markNotificationRead(notify!, completion: { (success) in })
                let label = notify?.object_type
                Analytics.event(category: "Notification", action: "click", label: label ?? "", value: nil)
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
    
    func notificationReceived() {
        loadNotifications(false)
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
                            var willBeDisplayed: Bool = false
                            if let site = self.site {
                                desiredSite = n.site_id == site.id
                                if let viewStyle = self.viewStyle {
                                    switch viewStyle {
                                    case .Discussions:
                                        willBeDisplayed = n.object_type == "discussion"
                                        break
                                    case .Dashboard:
                                        willBeDisplayed = true
                                        break
                                    }
                                }
                            } else {
                                willBeDisplayed = n.object_type == "announcement"
                                desiredSite = true
                            }
                            return !n.seen && desiredSite && willBeDisplayed
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
                    } else { //no notifications
                        DispatchQueue.main.async {
                            Utils.hideActivity()
                        }
                    }
                }
            }
        }
    }
    
    func convertIndex(indexPath: IndexPath) -> Int {
        var notificationType: String = ""
        var returnIndex = -1
        
        if let viewStyle = viewStyle {
            switch viewStyle {
            case .Dashboard:
                switch indexPath.section {
                case 0:
                    if announcementSection == 0 {
                        notificationType = Section.Announcements.rawValue
                    } else if discussionSection == 0 {
                        notificationType = Section.Discussions.rawValue
                    }
                case 1:
                    notificationType = Section.Discussions.rawValue
                default:
                    break
                }
                break
            case .Discussions:
                notificationType = Section.Discussions.rawValue
                break
            }
        } else {
            notificationType = Section.Announcements.rawValue
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
}
