//
//  CourseListController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class CourseListController: UIViewController, UITableViewDelegate, UITableViewDataSource, CourseCellDelegate {
    @IBOutlet var tableView:UITableView!
    var coursesites:[Site] = []
    var projectsites:[Site] = []
    var refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.save(false, withKey: "introScreen")
        tableView.register(UINib(nibName:"CourseCell", bundle: nil), forCellReuseIdentifier: "courselist")
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadWithActivity), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        let menubutton = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedMenu))
        menubutton.accessibilityLabel = "Menu"
        navigationItem.rightBarButtonItem = menubutton
        
        refresh.addTarget(self, action: #selector(load), for: .valueChanged)
        tableView.addSubview(refresh)
        TRACSClient.loginIfNecessary { (loggedin) in
            if !loggedin {
                let lvc = LoginViewController()
                self.present(lvc, animated: true, completion: nil)
            } else {
                IntegrationClient.registerIfNecessary()
            }
            if !Utils.flag("introScreen", val: true) {
                self.activateIntroScreen()
            }
        }
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
    
    func load() {
        if !TRACSClient.userid.isEmpty {
            TRACSClient.fetchSitesByMembership { (sitehash) in
                var courses:[Site] = []
                var projects:[Site] = []
                if let sitehash = sitehash {
                    for site in sitehash.values {
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? coursesites.count : projectsites.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Course Sites" : "Project Sites"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIFont.preferredFont(forTextStyle: .body).pointSize * 2.8 + 50.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CourseCell = tableView.dequeueReusableCell(withIdentifier: "courselist", for: indexPath) as! CourseCell
        cell.site = (indexPath.section == 0 ? coursesites : projectsites)[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CourseCell
        let siteUrl = "\(TRACSClient.tracsurl)/portal/site/\(cell.site?.id ?? "")"
        let wvc = WebViewController(urlToLoad: siteUrl)
        navigationController?.pushViewController(wvc!, animated: true)
    }

    // MARK: - CourseCellDelegate
    
    func discussionPressed(site:Site) {
        let wvc = WebViewController(urlToLoad: site.discussionurl)
        navigationController?.pushViewController(wvc!, animated: true)
    }
    func dashboardPressed(site: Site) {
        let nvc = NotificationViewController(nibName: "NotificationViewController", bundle: nil)
        nvc.site = site
        navigationController?.pushViewController(nvc, animated: true)
    }
}
