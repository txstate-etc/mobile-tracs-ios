//
//  SettingsViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/26/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsCellDelegate {
    @IBOutlet weak var tableView: UITableView!
    var sites:[Site] = []
    var settings: Settings?
    let objecttypes: [String] = [
        Announcement.type,
        Discussion.type
    ]
    let objectnames: [String] = [
        Announcement.displayplural,
        Discussion.displayplural
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Utils.showActivity(view)
        tableView.delegate = self
        tableView.dataSource = self
        
        let dispatch_group = DispatchGroup()
        var tmpsites:[Site] = []
        dispatch_group.enter()
        TRACSClient.fetchSitesByMembership { (sitehash) in
            if sitehash == nil { dispatch_group.leave(); return }
            for site in sitehash!.values {
                tmpsites.append(site)
            }
            tmpsites.sort(by: { (a, b) -> Bool in
                (!a.coursesite && b.coursesite) ||
                    a.title.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).lowercased() < b.title.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).lowercased()
            })
            dispatch_group.leave()
        }
        
        let tmpsettings = IntegrationClient.getRegistration().settings
        
        dispatch_group.notify(queue: .main) {
            self.settings = tmpsettings
            self.sites = tmpsites
            self.tableView.reloadData()
            Utils.hideActivity()
        }
        Analytics.viewWillAppear("Settings")
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if settings == nil { return 0 }
        return section == 0 ? objecttypes.count : sites.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Notification Types" : "Sites"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(UIFont.preferredFont(forTextStyle: .callout).pointSize * 2.5)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SettingsCell = tableView.dequeueReusableCell(withIdentifier: "settings", for: indexPath) as! SettingsCell
        if cell.delegate == nil { cell.delegate = self }

        if indexPath.section == 0 {
            cell.title.text = objectnames[indexPath.row]
            cell.entry = SettingsEntry(disabled_type: objecttypes[indexPath.row])
            cell.toggle.setOn(!settings!.objectTypeIsDisabled(type: objecttypes[indexPath.row]), animated: false)
        } else {
            cell.title.text = sites[indexPath.row].title
            cell.entry = SettingsEntry(disabled_site: sites[indexPath.row])
            cell.toggle.setOn(!settings!.siteIsDisabled(site: sites[indexPath.row]), animated: false)
        }

        return cell
    }
    
    // MARK: - SettingsCellDelegate
    
    func cellDidToggle(_ cell:SettingsCell, toggle:UISwitch) {
        if let settings = settings, let entry = cell.entry {
            if toggle.isOn { settings.enableEntry(entry) }
            else { settings.disableEntry(entry) }
            IntegrationClient.saveSettings(settings, completion: { (success) in
                Analytics.event(category: "Filter", action: toggle.isOn ? "allow" : "block", label: cell.title.text ?? "", value: nil)
            })
        }
    }
}
