//
//  CourseListController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/19/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class CourseListController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView:UITableView!
    var coursesites:[Site] = []
    var projectsites:[Site] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName:"CourseCell", bundle: nil), forCellReuseIdentifier: "courselist")
        NotificationCenter.default.addObserver(self, selector: #selector(load), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(load), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        let menubutton = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedMenu))
        menubutton.accessibilityLabel = "Menu"
        navigationItem.rightBarButtonItem = menubutton
        
        let lvc = LoginViewController()
        self.present(lvc, animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func load() {
        Utils.showActivity(view)
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
                } else {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.5, execute: { 
                        self.load()
                    })
                }
                DispatchQueue.main.async {
                    Utils.hideActivity()
                    self.coursesites = courses
                    self.projectsites = projects
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func pressedMenu() {
        let mvc = MenuViewController()
        navigationController?.pushViewController(mvc, animated: true)
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
        return cell
    }
    
}
