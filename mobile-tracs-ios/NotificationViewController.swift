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
    var notifications: [Notification] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationItem.hidesBackButton = true
        tableView.register(UINib(nibName:"NotificationCell", bundle: nil), forCellReuseIdentifier: "notification")
        navigationItem.rightBarButtonItem = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedSettings))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.viewWillAppear("NotificationViewController")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "notification", for: indexPath)
        let notify = notifications[indexPath.row]
        cell.textLabel?.text = notify.object?.titleForTable()
        cell.detailTextLabel?.text = notify.object?.tableSubtitle()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notify = notifications[indexPath.row]
        if notify.object == nil { return }
        let url = URL(string: notify.object!.getUrl())
        if url != nil {
            navigationController!.popViewController(animated: true)
            (navigationController!.viewControllers[0] as! WebViewController).webView.loadRequest(URLRequest(url: url!))
        }
    }
    
    func pressedSettings() {
        let svc = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        navigationController?.pushViewController(svc, animated: true)
    }
}
