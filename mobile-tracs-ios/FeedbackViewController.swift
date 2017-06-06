//
//  FeedbackViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/14/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import WebKit

class FeedbackViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet var webView:WKWebView!
    var urltoload:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.showActivity(view)
        webView = Utils.getWebView()
        view.addSubview(webView)
        Utils.constrainToContainer(view: webView, container: view)
        if let urltoload = self.urltoload, let url = URL(string: urltoload) {
            webView.load(URLRequest(url:url))
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Utils.hideActivity()
    }
}
