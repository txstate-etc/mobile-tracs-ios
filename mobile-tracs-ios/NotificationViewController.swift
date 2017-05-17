//
//  NotificationViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class NotificationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotificationCellDelegate {
    @IBOutlet var tableView: UITableView!
    var notifications: [Notification] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName:"NotificationCell", bundle: nil), forCellReuseIdentifier: "notification")
        navigationItem.rightBarButtonItem = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedSettings))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Utils.showActivity(view)
        Analytics.viewWillAppear("Notifications")
        IntegrationClient.getNotifications { (notifications) in
            let notis = notifications ?? []
            var unseen:[Notification] = []
            for n in notis {
                if !n.seen {
                    unseen.append(n)
                }
            }
            IntegrationClient.markNotificationsSeen(notifications: unseen, completion: { (success) in
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    self.notifications = notis
                    self.tableView.reloadData()
                    Utils.hideActivity()
                }
            })
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        cell.delegate = self
        let notify = notifications[indexPath.row]
        cell.notify = notify
        if let tracsobj = notify.object {
            cell.textLabel?.text = tracsobj.tableTitle()
            cell.detailTextLabel?.text = tracsobj.tableSubtitle()
            if !tracsobj.getUrl().isEmpty {
                cell.accessoryType = .disclosureIndicator
            }
        }
        return cell
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
        if let tracsobj = notifications[indexPath.row].object {
            if let url = URL(string: tracsobj.getUrl()) {
                Analytics.event(category: "Notification", action: "click", label: notifications[indexPath.row].object_type ?? "", value: nil)
                navigationController!.popViewController(animated: true)
                (navigationController!.viewControllers[0] as! WebViewController).webView.loadRequest(URLRequest(url: url))
            }
        }
    }
    
    func pressedSettings() {
        let svc = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        navigationController?.pushViewController(svc, animated: true)
    }
}
