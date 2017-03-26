//
//  SettingsViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView:UITableView!
    var sites: [Site] = []
    var settings: Settings?
    let objecttypes: [String] = [
        Announcement.type
    ]
    let objectnames: [String] = [
        Announcement.displayplural
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName:"SettingsCell", bundle: nil), forCellReuseIdentifier: "settings")

        let dispatch_group = DispatchGroup()
        var tmpsites:[Site] = []
        dispatch_group.enter()
        TRACSClient.fetchSites { (sitehash) in
            if sitehash == nil { dispatch_group.leave(); return }
            for site in sitehash!.values {
                tmpsites.append(site)
            }
            tmpsites.sort(by: { (a, b) -> Bool in
                a.title > b.title
            })
            dispatch_group.leave()
        }
        
        var tmpsettings:Settings?
        dispatch_group.enter()
        IntegrationClient.fetchSettings { (settings) in
            tmpsettings = settings
            dispatch_group.leave()
        }
        
        dispatch_group.notify(queue: .main) {
            self.settings = tmpsettings
            self.sites = tmpsites
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if settings == nil { return 0 }
        return section == 0 ? objecttypes.count : sites.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Notification Types" : "Sites"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SettingsCell = tableView.dequeueReusableCell(withIdentifier: "settings", for: indexPath) as! SettingsCell

        if indexPath.section == 0 {
            cell.title.text = objectnames[indexPath.row]
            cell.filter_key = "object_type"
            cell.filter_value = objecttypes[indexPath.row]
            cell.toggle.setOn(!settings!.objectTypeIsDisabled(type: objecttypes[indexPath.row]), animated: false)
        } else {
            cell.title.text = sites[indexPath.row].title
            cell.filter_key = "site_id"
            cell.filter_value = sites[indexPath.row].id
            cell.toggle.setOn(!settings!.siteIsDisabled(site: sites[indexPath.row]), animated: false)
        }
        if !cell.targetset {
            cell.toggle.addTarget(self, action: #selector(toggleChanged(sender:)), for: .valueChanged)
        }

        return cell
    }
    
    func toggleChanged(sender: UISwitch) {
        
    }
}
