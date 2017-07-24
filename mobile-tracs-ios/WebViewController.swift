//
//  WebViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/17/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import MessageUI
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, NotificationObserver {
    @IBOutlet var wvContainer: UIView!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var back: UIBarButtonItem!
    @IBOutlet var forward: UIBarButtonItem!
    @IBOutlet var refresh: UIBarButtonItem!
    @IBOutlet var interaction: UIBarButtonItem!
    var webview:WKWebView!

    var documentInteractionController: UIDocumentInteractionController?
    let documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    let stop = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop, target: self, action: #selector(pressedRefresh(sender:)))
    let loginUrl = Secrets.shared.loginbaseurl ?? "https://login.its.txstate.edu"
    var urlToLoad: String?
    var bellnumber: Int?
    var wasLogout = false
    var urltoload:String?
        
    init? (urlToLoad: String, _ coder: NSCoder? = nil) {
        self.urlToLoad = urlToLoad
        
        if let coder = coder {
            super.init(coder: coder)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
    }
    
    required convenience init(coder: NSCoder) {
        self.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.showActivity(view)
        
        webview = Utils.getWebView()
        wvContainer.addSubview(webview)
        Utils.constrainToContainer(view: webview, container: wvContainer)
        webview.navigationDelegate = self
        webview.uiDelegate = self
        
        updateBell()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBell), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBell), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        back = Utils.fontAwesomeBarButtonItem(icon: .chevronLeft, target: self, action: #selector(pressedBack(sender:)))
        forward = Utils.fontAwesomeBarButtonItem(icon: .chevronRight, target: self, action: #selector(pressedForward(sender:)))
        
        var tb = toolBar.items!
        tb[1] = back;
        tb[3] = forward;
        toolBar.setItems(tb, animated: false)
        
        refresh.action = #selector(pressedRefresh(sender:))
        interaction.action = #selector(pressedInteraction(sender:))

        back.accessibilityLabel = "back"
        forward.accessibilityLabel = "forward"
        
        self.load()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.viewWillAppear("WebView")
        TRACSClient.waitForLogin { (loggedin) in
            self.updateBell()
        }
    }
    
    // MARK: - Helper functions
    func load() {
        loginIfNecessary { (loggedin) in
            if loggedin {
                let urlString = self.urlToLoad ?? TRACSClient.portalurl
                if let url = URL(string: urlString) {
                    let req = URLRequest(url: url)
                    self.webview.load(req)
                }
            }
        }
    }
    
    func loginIfNecessary(completion:@escaping(Bool)->Void) {
        TRACSClient.loginIfNecessary { (loggedin) in
            DispatchQueue.main.async {
                self.updateBell()
                completion(loggedin)
            }
        }
    }
    
    // MARK: - Button Presses
    func pressedBack(sender: UIBarButtonItem!) {
        webview.goBack()
    }
    func pressedForward(sender: UIBarButtonItem!) {
        webview.goForward()
    }
    func pressedRefresh(sender: UIBarButtonItem!) {
        if webview.isLoading { webview.stopLoading() }
        else { webview.reload() }
    }
    func pressedInteraction(sender: UIBarButtonItem!) {
        let fileUrl = webview.url
        if fileUrl == nil { return }
        
        let filename = fileUrl?.lastPathComponent;
        let downloadpath = documentsPath+"/"+filename!
        let downloadurl = URL(fileURLWithPath: downloadpath)
        interaction.isEnabled = false
        URLSession.shared.dataTask(with: fileUrl!) { (tmp, response, error) in
            if (error != nil) {
                NSLog("Unable to download file. %@", error!.localizedDescription)
                return
            }
            
            // Save the loaded data if loaded successfully
            do {
                try tmp!.write(to: downloadurl, options: [Data.WritingOptions.atomicWrite])
            } catch {
                NSLog("Failed to save the file to disk. %@", error.localizedDescription)
                return
            }
            
            NSLog("Saved file to location: %@", downloadpath)
            
            // Initialize Document Interaction Controller in main thread
            DispatchQueue.main.async {
                self.documentInteractionController = UIDocumentInteractionController(url: downloadurl)
                self.documentInteractionController?.delegate = self
                self.documentInteractionController?.presentOptionsMenu(from: CGRect.zero, in: self.view, animated: true)
            }
        }.resume()
    }
    func pressedBell() {
        let nvc = NotificationViewController(nibName: "NotificationViewController", bundle: nil)
        navigationController?.pushViewController(nvc, animated: true)
    }
    func pressedMenu() {
        let mvc = MenuViewController()
        navigationController?.pushViewController(mvc, animated: true)
    }    

    func updateButtons() {
        forward.isEnabled = webview.canGoForward
        back.isEnabled = webview.canGoBack
        var tb = toolBar.items!
        tb[5] = (webview.isLoading ? stop : refresh);
        toolBar.setItems(tb, animated: false)

        interaction.isEnabled = false
        
        if let ext = webview.url?.pathExtension.lowercased() {
            if !ext.isEmpty && ext != "html" {
                interaction.isEnabled = true
            }
        }
    }
    
    func updateBell() {
        let newnumber = UIApplication.shared.applicationIconBadgeNumber
        if bellnumber != newnumber {
            let menubutton = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedMenu))
            menubutton.accessibilityLabel = "Menu"
            bellnumber = newnumber
            let bellbutton = Utils.fontAwesomeBadgedBarButtonItem(color: (navigationController?.navigationBar.tintColor)!, badgecount:newnumber, icon: .bellO, target: self, action: #selector(pressedBell))
            bellbutton.accessibilityLabel = String(bellnumber!)+" Notification"+(bellnumber != 1 ? "s" : "")
            bellbutton.accessibilityHint = "open notifications screen"
            navigationItem.rightBarButtonItems = [
                menubutton,
                bellbutton
            ]
        }
        if let btn = self.navigationItem.rightBarButtonItems?[1].customView as? UIButton {
            btn.isEnabled = !TRACSClient.userid.isEmpty
        }
    }
    
    // MARK: - UIWebViewDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateButtons()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateButtons()
        Utils.hideActivity()

        if let urlstring = webView.url?.absoluteString {
            if urlstring.hasPrefix(TRACSClient.tracsurl) && TRACSClient.userid.isEmpty {
                loginIfNecessary(completion: { (loggedin) in
                    
                })
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("webView didFail navigation %@", error.localizedDescription)
        updateButtons()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlstring = navigationAction.request.url?.absoluteString {
            if navigationAction.request.url?.scheme == "mailto" {
                Analytics.event(category: "E-mail", action: "compose", label: urlstring, value: nil)
                let mvc = MFMailComposeViewController()
                mvc.mailComposeDelegate = self
                
                let rawcomponents = urlstring.characters.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
                let mailtocomponents = rawcomponents[1].characters.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
                let recipients = mailtocomponents[0].components(separatedBy: ";")
                var params = [String:String]()
                if mailtocomponents.count == 2 {
                    let pairs = mailtocomponents[1].components(separatedBy: "&")
                    for pair in pairs {
                        let p = pair.components(separatedBy: "=")
                        let key = p[0].removingPercentEncoding?.lowercased()
                        let value = p[1].removingPercentEncoding
                        if p.count == 2 {
                            params[key!] = value
                        }
                    }
                }
                
                mvc.setToRecipients(recipients)
                if !(params["subject"] ?? "").isEmpty { mvc.setSubject(params["subject"]!) }
                if !(params["body"] ?? "").isEmpty { mvc.setMessageBody(params["body"]!, isHTML: false) }
                if !(params["cc"] ?? "").isEmpty { mvc.setCcRecipients(params["cc"]?.components(separatedBy: ";")) }
                if !(params["bcc"] ?? "").isEmpty { mvc.setBccRecipients(params["bcc"]?.components(separatedBy: ";")) }
                self.present(mvc, animated: true, completion: nil)
                return decisionHandler(.cancel)
            }
            Analytics.linkClick(urlstring)
            if urlstring == "about:blank" {
                return decisionHandler(.cancel)
            }
            if urlstring.contains(TRACSClient.logouturl) || urlstring.contains(TRACSClient.altlogouturl) {
                TRACSClient.userid = ""
                Utils.removeCredentials()
                IntegrationClient.unregister()
                UIApplication.shared.applicationIconBadgeNumber = 0
                wasLogout = true
            }
        }
        decisionHandler(.allow)
    }
    
    // this handles target=_blank links by opening them in the same view
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // MARK: - UIDocumentInteractionControllerDelegate
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        interaction.isEnabled = true
        do {
            try FileManager.default.removeItem(at: controller.url!)
            NSLog("deleted temporary file at %@", controller.url?.absoluteString ?? "nil")
        } catch {
            NSLog("documentInteractionController was unable to clean up after itself")
        }
    }

    // MARK: - MFMailComposeViewControllerDelegate
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - NotificationObserver
    func incomingNotification(badgeCount: Int?, message: String?) {
        updateBell()
    }
}
