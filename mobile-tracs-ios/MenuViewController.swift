//
//  MenuViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/29/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView:UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "menuitem")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let ip = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: ip, animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
 
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 3 }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuitem", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        if indexPath.section == 0 && indexPath.row == 0 {
            cell.textLabel?.text = "Notification Settings"
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Intro Page"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Give us Feedback"
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "TRACS Support"
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            cell.textLabel?.text = "Go to TXST Mobile"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let vc = SettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let vc = IntroViewController()
                self.present(vc, animated: true, completion: nil)
            } else if indexPath.row == 1 {
                let vc = FeedbackViewController()
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 {
                // start an email?
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            if let url = URL(string: "edu.txstate.mobile://") {
                Analytics.event(category: "External", action: "click", label: url.absoluteString, value: nil)
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }

}
