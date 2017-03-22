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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        IntegrationClient.getNotifications { (notifications) in
            self.notifications = notifications ?? []
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
        cell.textLabel?.text = notify.object?.table_title
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
    
}
