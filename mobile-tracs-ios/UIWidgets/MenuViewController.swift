//
//  MenuViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/13/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

protocol MenuViewControllerDelegate {
    func menuViewController(_ mvc:MenuViewController, pressed:MenuItem)
}

class MenuViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    var menuitems:[MenuItem] = []
    var delegate:MenuViewControllerDelegate?
    
    init(delegate:MenuViewControllerDelegate, bbi:UIBarButtonItem) {
        super.init(style: .plain)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuItemCell")
        menuitems.append(.home)
        menuitems.append(.settings)
        menuitems.append(.feedback)
        menuitems.append(.txstate)
        menuitems.append(.intro)
        self.delegate = delegate
        modalPresentationStyle = .popover
        popoverPresentationController?.delegate = self
        popoverPresentationController?.barButtonItem = bbi
        popoverPresentationController?.permittedArrowDirections = .up
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        self.preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }

    // MARK: - Table view data source / delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuitems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCell", for: indexPath)

        let item = menuitems[indexPath.row]
        cell.imageView?.image = UIImage.fontAwesomeIcon(name: item.icon, textColor: UIColor.black, size: CGSize(width: 200, height: 200))
        cell.textLabel?.text = item.label
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = delegate {
            delegate.menuViewController(self, pressed: menuitems[indexPath.row])
        }
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
