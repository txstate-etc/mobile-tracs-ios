//
//  MenuViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/29/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import StoreKit

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SKStoreProductViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(deselectRow), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deselectRow), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        deselectRow()
    }
    
    // MARK: - Helper functions
    
    func deselectRow() {
        if let ip = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: ip, animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
 
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows: Int
        switch section {
        case 1:
            rows = 3
        default:
            rows = 1
        }
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuitem", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Notification Settings"
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "About the App"
            case 1:
                cell.textLabel?.text = "Give us Feedback"
            case 2:
                cell.textLabel?.text = "TRACS Support"
            default:
                break
            }
        case 2:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Go to TXST Mobile"
            }
        case 3:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Logout"
            }
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let settingsStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
            let settingsVC = settingsStoryBoard.instantiateViewController(withIdentifier: "NotificationSettings")
            navigationController?.pushViewController(settingsVC, animated: true)
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let vc = IntroViewController()
                self.present(vc, animated: true, completion: nil)
            } else if indexPath.row == 1 { // Give us Feedback
                let vc = FeedbackViewController()
                vc.urltoload = Secrets.shared.surveyurl
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.row == 2 { // TRACS Support
                let vc = FeedbackViewController()
                vc.urltoload = Secrets.shared.contacturl
                navigationController?.pushViewController(vc, animated: true)
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            if let url = URL(string: "edu.txstate.mobile://") {
                Analytics.event(category: "External", action: "click", label: url.absoluteString, value: nil)
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                } else {
                    let appstore = SKStoreProductViewController()
                    appstore.delegate = self
                    let parameters = [SKStoreProductParameterITunesItemIdentifier:NSNumber(value: 373345139)]
                    appstore.loadProduct(withParameters: parameters, completionBlock: { (result, err) in
                        if result {
                            self.present(appstore, animated: true, completion: nil)
                        }
                    })
                }
            }
        } else if indexPath.section == 3 && indexPath.row == 0 {
            TRACSClient.userid = ""
            Utils.removeCredentials()
            IntegrationClient.unregister()
            UIApplication.shared.applicationIconBadgeNumber = 0
            let cookies = HTTPCookieStorage.shared.cookies
            for cookie in cookies! {
                if cookie.name == "JSESSIONID" {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
            for cookie in HTTPCookieStorage.shared.cookies! {
                print("\(cookie.name): \(cookie.value)")
            }
            let clStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
            let clc = clStoryBoard.instantiateViewController(withIdentifier: "SiteList")
            navigationController?.pushViewController(clc, animated: true)
        }
    }

    // MARK: - SKStoreProductViewControllerDelegate
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated:true, completion:nil)
    }
}
