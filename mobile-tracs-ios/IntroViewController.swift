//
//  IntroViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/16/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import WebKit

class IntroViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet var webView:WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = Utils.getWebView()
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.bounces = false
        let taprecognizer = UITapGestureRecognizer(target: self, action: #selector(okPressed))
        taprecognizer.delegate = self
        webView.scrollView.addGestureRecognizer(taprecognizer)
        view.addSubview(webView)
        Utils.constrainToContainer(view: webView, container: view)
        let htmlpath = Bundle.main.path(forResource: "welcome_page", ofType: "html")
        let folderpath = Bundle.main.bundlePath
        let baseurl = URL(fileURLWithPath: folderpath, isDirectory: true)
        do {
            let htmlstring = try NSString(contentsOfFile: htmlpath!, encoding: String.Encoding.utf8.rawValue)
            webView.loadHTMLString(htmlstring as String, baseURL: baseurl)
        } catch {
            NSLog("IntroViewController could not load html!")
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.webView.scrollView.zoomScale = 1.0
            self.webView.evaluateJavaScript("document.body.style.zoom = 1.0", completionHandler: nil)
        }
    }
    
    func okPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
