//
//  CourseListController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class CourseListController: UIViewController, UITableViewDelegate, UITableViewDataSource, CourseCellDelegate  {
    @IBOutlet weak var tableView: UITableView!
    var coursesites:[Site] = []
    var projectsites:[Site] = []
    var workspace: Site = Site(dict: [:])
    var unseenBySite: [String: Int] = [:]
    var refresh = UIRefreshControl()
    
    enum Sections: Int {
        case workspace, courses, projects
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.showActivity(view)
        TRACSClient.loginIfNecessary { (loggedin) in
            if !loggedin {
                let lvc = LoginViewController()
                DispatchQueue.main.async {
                    Utils.hideActivity()
                }
                self.present(lvc, animated: true, completion: nil)
            } else {
                TRACSClient.fetchSite(id: "~\(TRACSClient.useruuid)") {
                    (workspaceSite) in
                    if let workspaceSite = workspaceSite {
                        self.workspace = workspaceSite
                    }
                }
                IntegrationClient.registerIfNecessary()
                IntegrationClient.getDispatchNotifications {
                    (notifications) in
                    if (notifications != nil) {
                        self.unseenBySite = self.countUnseenBySite(notifications: notifications!)
                    }
                    DispatchQueue.main.async {
                        Utils.hideActivity()
                    }
                }
            }
            if !Utils.flag("introScreen", val: true) {
                self.activateIntroScreen()
            }
        }
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView.tableFooterView = UIView()

        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        refresh.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView?.addSubview(refresh)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        TRACSClient.waitForLogin { (loggedin) in
            self.loadWithActivity()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadWithActivity() {
        Utils.showActivity(view)
        load()
    }
    
    func countUnseenBySite(notifications: [Any]) -> [String: Int] {
        var unseen: [String: Int] = [:]
        for notif in notifications {
            let notif = notif as! [String: Any]
            let seen = notif["seen"] as? Bool ?? true
            if !seen {
                if let otherkeys = notif["other_keys"] as? [String: Any] {
                    if let site_id = otherkeys["site_id"] as? String {
                        var count = unseen[site_id] ?? 0
                        count += 1
                        unseen[site_id] = count
                    }
                }
            }
        }
        return unseen
    }
    
    func load() {
        if !TRACSClient.userid.isEmpty {
            IntegrationClient.getDispatchNotifications(completion: { (dispatchnotifs) in
                if dispatchnotifs != nil {
                self.unseenBySite = self.countUnseenBySite(notifications: dispatchnotifs!)
                }
                TRACSClient.fetchSitesByMembership { (sitehash) in
                    var courses:[Site] = []
                    var projects:[Site] = []
                    if let sitehash = sitehash {
                        for site in sitehash.values {
                            site.unseenCount = self.unseenBySite[site.id] ?? 0
                            if site.coursesite {
                                courses.append(site)
                            } else {
                                projects.append(site)
                            }
                        }
                        let comparator: (Site,Site)->Bool = { (a, b) in
                            (!a.coursesite && b.coursesite) ||
                                a.title.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).lowercased() < b.title.trimmingCharacters(in:CharacterSet.whitespacesAndNewlines).lowercased()
                        }
                        courses.sort(by: comparator)
                        projects.sort(by: comparator)
                        
                        DispatchQueue.main.async {
                            Utils.hideActivity()
                            self.coursesites = courses
                            self.projectsites = projects
                            self.tableView.reloadData()
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: {
                            self.load()
                        })
                    }
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.4, execute: {
                        self.refresh.endRefreshing()
                    })
                }
            })
        }
    }
    
    func pressedMenu() {
        let mvc = MenuViewController()
        navigationController?.pushViewController(mvc, animated: true)
    }
    func activateIntroScreen() {
        let ivc = IntroViewController()
        self.present(ivc, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections: Int = 1
        if coursesites.count > 0 { sections += 1 }
        if projectsites.count > 0 { sections += 1 }
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionName: Sections? = Sections(rawValue: section)
        var rowCount: Int = 0
        if let sectionName = sectionName {
            switch sectionName {
            case .workspace:
                rowCount = 1
                break
            case .courses:
                rowCount = coursesites.count
                break
            case .projects:
                rowCount = projectsites.count
                break
            }
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionName: Sections? = Sections(rawValue: section)
        var name: String = ""
        if let sectionName = sectionName {
            switch sectionName {
            case .courses:
                name = "Course Sites"
                break
            case .projects:
                name = "Project Sites"
                break
            default:
                break
            }
        }
        return name
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: .body).pointSize * 2.8 + 50.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CourseCell = tableView.dequeueReusableCell(withIdentifier: "courselist", for: indexPath) as! CourseCell
        cell.contentView.backgroundColor = UIColor.clear
        let sectionName: Sections? = Sections(rawValue: indexPath.section)
        if let sectionName = sectionName {
            switch sectionName {
            case .workspace:
                cell.site = workspace
                break
            case .courses:
                cell.site = coursesites[indexPath.row]
                break
            case .projects:
                cell.site = projectsites[indexPath.row]
                break
            }
        }
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CourseCell
        
        let siteUrl = "\(TRACSClient.tracsurl)/portal/pda/\(cell.site?.id ?? "")"
        loadWebViewWithUrl(url: siteUrl)
        
    }
    
    // MARK: - CourseCellDelegate
    
    func discussionPressed(site: Site) {
        loadWebViewWithUrl(url: site.discussionurl)
    }
    
    func dashboardPressed(site: Site) {
        let dbStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
        let dbController = dbStoryBoard.instantiateViewController(withIdentifier: "Dashboard")
        (dbController as! NotificationViewController).site = site
        navigationController?.pushViewController(dbController, animated: true)
    }
    
    func loadWebViewWithUrl(url: String) {
        let wvStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
        let wvController = wvStoryBoard.instantiateViewController(withIdentifier: "TracsWebView")
        (wvController as! WebViewController).urlToLoad = url
        navigationController?.pushViewController(wvController, animated: true)
    }
}
