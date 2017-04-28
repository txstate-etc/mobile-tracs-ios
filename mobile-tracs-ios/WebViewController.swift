//
//  WebViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/17/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import MessageUI

class WebViewController: UIViewController, UIWebViewDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate {
    @IBOutlet var webView: UIWebView!
    @IBOutlet var toolBar: UIToolbar!
    @IBOutlet var back: UIBarButtonItem!
    @IBOutlet var forward: UIBarButtonItem!
    @IBOutlet var refresh: UIBarButtonItem!
    @IBOutlet var interaction: UIBarButtonItem!

    var documentInteractionController: UIDocumentInteractionController?
    let documentsPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    let stop = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.stop, target: self, action: #selector(pressedRefresh(sender:)))
    var bellnumber: Int?
    var needtoregister = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Utils.showActivity(view)
        navigationItem.rightBarButtonItem = Utils.fontAwesomeBarButtonItem(icon: .gear, target: self, action: #selector(pressedSettings))

        updateBell()

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
        
        TRACSClient.waitForLogin { (loggedin) in
            NSLog("loading webview")
            let urlStringToLoad = loggedin ? TRACSClient.portalurl : TRACSClient.loginurl
            if let urlToLoad = URL(string: urlStringToLoad) {
                self.webView.loadRequest(URLRequest(url: urlToLoad))
            }
            Utils.hideActivity()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.viewWillAppear("WebView")
        TRACSClient.waitForLogin { (loggedin) in
            self.updateBell()
        }
    }
    
    // MARK: - Helper functions
    
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
        webView.goBack()
    }
    func pressedForward(sender: UIBarButtonItem!) {
        webView.goForward()
    }
    func pressedRefresh(sender: UIBarButtonItem!) {
        if webView.isLoading { webView.stopLoading() }
        else { webView.reload() }
    }
    func pressedInteraction(sender: UIBarButtonItem!) {
        let fileUrl = webView.request?.url;
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
    func updateButtons() {
        forward.isEnabled = webView.canGoForward
        back.isEnabled = webView.canGoBack
        var tb = toolBar.items!
        tb[5] = (webView.isLoading ? stop : refresh);
        toolBar.setItems(tb, animated: false)

        interaction.isEnabled = false
        if URLCache.shared.cachedResponse(for: webView.request!) != nil {
            interaction.isEnabled = true
        } else {
            if let ext = webView.request?.url?.pathExtension.lowercased() {
                if !ext.isEmpty && ext != "html" {
                    interaction.isEnabled = true
                }
            }
        }
    }
    
    func updateBell() {
        let newnumber = UIApplication.shared.applicationIconBadgeNumber
        if bellnumber != newnumber {
            bellnumber = newnumber
            navigationItem.leftBarButtonItem = Utils.fontAwesomeBadgedBarButtonItem(color: Utils.gold, badgecount:newnumber, icon: .bellO, target: self, action: #selector(pressedBell))
            navigationItem.leftBarButtonItem?.accessibilityLabel = "Notifications"
        }
        if let btn = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            btn.isEnabled = !TRACSClient.userid.isEmpty
        }
        if let btn = self.navigationItem.rightBarButtonItem {
            btn.isEnabled = !TRACSClient.userid.isEmpty
        }
   }
    
    // MARK: - UIWebViewDelegate
    func webViewDidStartLoad(_ webView: UIWebView) {
        updateButtons()
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        updateButtons()
        if let urlstring = webView.request?.url?.absoluteString {
            if urlstring.hasPrefix(TRACSClient.tracsurl) && TRACSClient.userid.isEmpty {
                loginIfNecessary(completion: { (loggedin) in
                    
                })
            }
        }
        if needtoregister {
            loginIfNecessary(completion: { (success) in
                if success {
                    IntegrationClient.register({ (success) in
                        if success {
                            self.needtoregister = false
                        }
                    })
                }
            })
        }
    }
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        updateButtons()
    }
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.scheme == "mailto" {
            Analytics.event(category: "E-mail", action: "compose", label: request.url?.absoluteString ?? "", value: nil)
            let mvc = MFMailComposeViewController()
            mvc.mailComposeDelegate = self
            
            let rawcomponents = request.url?.absoluteString.characters.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            let mailtocomponents = rawcomponents?[1].characters.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            let recipients = mailtocomponents?[0].components(separatedBy: ";")
            var params = [String:String]()
            if mailtocomponents?.count == 2 {
                let pairs = mailtocomponents?[1].components(separatedBy: "&")
                if pairs != nil {
                    for pair in pairs! {
                        let p = pair.components(separatedBy: "=")
                        let key = p[0].removingPercentEncoding?.lowercased()
                        let value = p[1].removingPercentEncoding
                        if p.count == 2 {
                            params[key!] = value
                        }
                    }
                }
            }
            
            if recipients != nil { mvc.setToRecipients(recipients!) }
            if !(params["subject"] ?? "").isEmpty { mvc.setSubject(params["subject"]!) }
            if !(params["body"] ?? "").isEmpty { mvc.setMessageBody(params["body"]!, isHTML: false) }
            if !(params["cc"] ?? "").isEmpty { mvc.setCcRecipients(params["cc"]?.components(separatedBy: ";")) }
            if !(params["bcc"] ?? "").isEmpty { mvc.setBccRecipients(params["bcc"]?.components(separatedBy: ";")) }
            self.present(mvc, animated: true, completion: nil)
            return false;
        }
        if let urlstring = request.url?.absoluteString {
            NSLog(urlstring)
            Analytics.linkClick(urlstring)
            if urlstring == "about:blank" {
                return false
            }
            if request.httpMethod == "POST" {
                if let body = request.httpBody {
                    if let body = String(data: body, encoding: .utf8) {
                        let params = Utils.stringToParams(body)
                        if params["publicWorkstation"] == nil {
                            if let netid = params["username"], let pw = params["password"] {
                                Utils.store(netid: netid, pw: pw)
                                needtoregister = true
                            }
                        }
                    }
                }
            }
            if urlstring.contains(TRACSClient.logouturl) || urlstring.contains(TRACSClient.altlogouturl) {
                TRACSClient.userid = ""
                Utils.removeCredentials()
                IntegrationClient.unregister()
                updateBell()
            }
        }
        return true
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

    func pressedSettings() {
        let svc = SettingsViewController(nibName: "SettingsViewController", bundle: nil)
        navigationController?.pushViewController(svc, animated: true)
    }

}
