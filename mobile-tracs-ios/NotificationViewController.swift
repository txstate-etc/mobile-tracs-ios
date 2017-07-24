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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName:"NotificationCell", bundle: nil), forCellReuseIdentifier: "notification")
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath) as! NotificationCell
        let notify = notifications[indexPath.row]
        if let tracsobj = notify.object {
            cell.isRead = notify.isRead()
            cell.iView.image = UIImage.fontAwesomeIcon(name: tracsobj.getIcon(), textColor: Utils.nearblack, size:CGSize(width: 200, height: 200))
            cell.titleLabel.text = tracsobj.tableTitle()
            cell.titleLabel.font = notify.isRead() ? UIFont.preferredFont(forTextStyle: .body) : Utils.boldPreferredFont(style: .body)
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
                                    if let site = self.site {
                                        return n.site_id == site.id
                                    } else {
                                        return true
                                    }
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
