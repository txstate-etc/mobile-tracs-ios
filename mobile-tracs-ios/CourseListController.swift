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
    var unseenBySite: [String: [String: Int]] = [:]
    var refresh = UIRefreshControl()
    var workspaceCell: CourseCell?

    enum Sections: Int {
        case workspace, courses, projects
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView.tableFooterView = UIView()
        applyNavBarShadow()
        tableView.register(UINib(nibName: "SiteHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "siteheader")
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithoutActivity), name: NSNotification.Name(rawValue: ObservableEvent.PUSH_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        refresh.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView?.addSubview(refresh)
        self.clearTableView()
        Utils.showActivity(view)
    }

    
    func applyNavBarShadow() {
        self.navigationController?.navigationBar.layer.masksToBounds = false
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.8
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.navigationController?.navigationBar.layer.shadowRadius = 2
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            Utils.showActivity(self.view)
        }
        TRACSClient.loginIfNecessary { (loggedin) in
            if !loggedin {
                let lvc = LoginViewController()
                self.clearTableView()
                DispatchQueue.main.async {
                    Utils.hideActivity()
                    self.present(lvc, animated: true) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            } else {
                TRACSClient.fetchSite(id: "~\(TRACSClient.useruuid)") {
                    (workspaceSite) in
                    if let workspaceSite = workspaceSite {
                        self.workspace = workspaceSite
                    }
                }
                IntegrationClient.registerIfNecessary()
            }
            self.loadWithActivity()
        }
    }

    func clearTableView() {
        coursesites = []
        projectsites = []
        workspace = Site(dict: [:])
        unseenBySite = [:]
        TRACSClient.sitecache.reset()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadWithActivity() {
        DispatchQueue.main.async {
            Utils.showActivity(self.view)
        }
        load()
    }
    
    func loadWithoutActivity() {
        load()
    }
    
    func countUnseenBySite(notifications: [Any]) -> [String: [String: Int]] {
        var unseen: [String: [String: Int]] = [:]
        for notif in notifications {
            let notif = notif as! [String: Any]
            let seen = notif["seen"] as? Bool ?? true
            if !seen {
                if let otherkeys = notif["other_keys"] as? [String: Any] {
                    if let site_id = otherkeys["site_id"] as? String {
                        let type = (notif["keys"] as? [String: Any])?["object_type"] as? String
                        if let type = type {
                            var count = unseen[site_id]?[type] ?? 0
                            count += 1
                            var site_counts = unseen[site_id] ?? [:]
                            site_counts[type] = count
                            unseen[site_id] = site_counts
                        }
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
                var announceCount = 0
                for (_, value) in self.unseenBySite {
                    announceCount += value["announcement"] ?? 0
                }
                DispatchQueue.main.async {
                    (self.tabBarController as? TabBarController)?.updateAnnounceCount(count: announceCount)
                }
                TRACSClient.fetchSitesByMembership { (sitehash) in
                    var courses:[Site] = []
                    var projects:[Site] = []
                    if let sitehash = sitehash {
                        for site in sitehash.values {
                            site.unseenCount = 0
                            for (_, value) in self.unseenBySite[site.id] ?? [:] {
                                site.unseenCount += value
                            }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionName: Sections? = Sections(rawValue: section)
        var headerTitle: String = ""
        var header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "siteheader") as? SiteViewHeader
        if let sectionName = sectionName {
            switch sectionName {
            case .courses:
                headerTitle = "COURSES"
                break
            case .projects:
                headerTitle = "PROJECTS"
                break
            default:
                header = nil
                break
            }
        }
        let headerFontSize = UIFont.preferredFont(forTextStyle: .body).pointSize * 0.75
        header?.content.backgroundColor = SiteColor.headerBackground
        header?.title.textColor = SiteColor.headerText
        header?.title.font = UIFont.boldSystemFont(ofSize: headerFontSize)
        
        header?.title.text = headerTitle
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionName: Sections? = Sections(rawValue: section)
        var headerHeight = CGFloat(UIFont.preferredFont(forTextStyle: .body).pointSize * 1.0 + 15.0)
        if let sectionName = sectionName {
            switch sectionName {
            case .courses:
                break
            case .projects:
                break
            default:
                headerHeight = CGFloat(0)
                break
            }
        }
        
        return headerHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = CGFloat(UIFont.preferredFont(forTextStyle: .body).pointSize * 5.0 + 50.0)
        if indexPath.section == 0 {
            height = CGFloat(UIFont.preferredFont(forTextStyle: .body).pointSize * 3.0 + 30.0)
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chevX: CGFloat = 17
        let chevY: CGFloat = chevX
        let chevronSize = CGSize(width: chevX, height: chevY)
        
        let sectionName: Sections? = Sections(rawValue: indexPath.section)
        var cell: UITableViewCell?
        if let sectionName = sectionName {
            let cellType: String = sectionName == .workspace ? "workspace" : "courselist"
            cell = tableView.dequeueReusableCell(withIdentifier: cellType)!
            switch sectionName {
            case .workspace:
                let buttonImage = UIImage.fontAwesomeIcon(name: .ellipsisH, textColor: SiteColor.workspaceText, size: CGSize(width: 20, height: 20))
                let wscell = (cell as! WorkspaceCell)
                wscell.moreButton.tintColor = SiteColor.workspaceText
                wscell.site = workspace
                wscell.moreButton.setImage(buttonImage, for: .normal)
                wscell.moreButton.isUserInteractionEnabled = false
                wscell.moreButton.setTitleColor(SiteColor.workspaceText, for: .normal)
                wscell.contentView.backgroundColor = SiteColor.workspaceBackground
                wscell.titleLabel.font = UIFont.boldSystemFont(ofSize: wscell.titleLabel.font.pointSize)
                break
            case .courses:
                let courseCell = cell as! CourseCell
                courseCell.rightChevron.image = UIImage.fontAwesomeIcon(name: .chevronRight, textColor: SiteColor.courseText, size: chevronSize)
                courseCell.badgeCounts = unseenBySite[(coursesites[indexPath.row]).id] ?? [:]
                courseCell.site = coursesites[indexPath.row]
                courseCell.siteWord.textColor = SiteColor.courseText
                courseCell.contentView.backgroundColor = SiteColor.courseBackground
                courseCell.delegate = self
                break
            case .projects:
                let projectCell = cell as! CourseCell
                projectCell.rightChevron.image = UIImage.fontAwesomeIcon(name: .chevronRight, textColor: SiteColor.projectText, size: chevronSize)
                projectCell.badgeCounts = unseenBySite[(projectsites[indexPath.row]).id] ?? [:]
                projectCell.site = projectsites[indexPath.row]
                projectCell.siteWord.textColor = SiteColor.projectText
                projectCell.contentView.backgroundColor = SiteColor.projectBackground
                projectCell.delegate = self
                break
            }
        }
        cell?.selectionStyle = UITableViewCellSelectionStyle.none
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var cell: UITableViewCell
        var siteUrl: String
        if indexPath.section == 0 {
            cell = tableView.cellForRow(at: indexPath)!
            siteUrl = "\(TRACSClient.tracsurl)/portal/pda/\((cell as! WorkspaceCell).site?.id ?? "")"
        } else {
            cell = tableView.cellForRow(at: indexPath)!
            siteUrl = "\(TRACSClient.tracsurl)/portal/pda/\((cell as! CourseCell).site?.id ?? "")"
        }
        loadWebViewWithUrl(url: siteUrl)
    }
    
    // MARK: - CourseCellDelegate
    
    func discussionPressed(site: Site) {
        let discStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
        let discController = discStoryBoard.instantiateViewController(withIdentifier: "Dashboard")
        (discController as! NotificationViewController).site = site
        (discController as! NotificationViewController).viewStyle = NotificationViewController.Style.Discussions
        navigationController?.pushViewController(discController, animated: true)
    }
    
    func dashboardPressed(site: Site) {
        let dbStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
        let dbController = dbStoryBoard.instantiateViewController(withIdentifier: "Dashboard")
        (dbController as! NotificationViewController).site = site
        (dbController as! NotificationViewController).viewStyle = NotificationViewController.Style.Dashboard
        navigationController?.pushViewController(dbController, animated: true)
    }
    
    func loadWebViewWithUrl(url: String) {
        let wvStoryBoard = UIStoryboard(name: "MainStory", bundle: nil)
        let wvController = wvStoryBoard.instantiateViewController(withIdentifier: "TracsWebView")
        (wvController as! WebViewController).urlToLoad = url
        navigationController?.pushViewController(wvController, animated: true)
    }
}
