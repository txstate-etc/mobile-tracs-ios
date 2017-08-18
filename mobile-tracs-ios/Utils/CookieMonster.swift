//
//  CookieMonster.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 7/24/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation
import WebKit

class CookieMonster : NSObject, WKNavigationDelegate {
    var webView:WKWebView!
    var callback:(()->Void)!
    var addedtowindow = false
    
    func load(completion:@escaping()->Void) {
        callback = completion
        DispatchQueue.main.async {
            self.webView = Utils.getWebView()
            self.webView.navigationDelegate = self
            if !self.addedtowindow {
                UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(self.webView)
                self.addedtowindow = true
            }
            if let urltoload = URL(string: TRACSClient.portalurl) {
                NSLog("loading")
                self.wipecookies {
                    self.webView.load(URLRequest(url: urltoload))
                }
            }
        }
        
    }
    
    func wipecookies(completion:@escaping()->Void) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { (records) in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records, completionHandler: completion)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        NSLog("decidePolicyFor navigationAction")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        NSLog("decidePolicyFor navigationResponse")
        if let resp = navigationResponse.response as? HTTPURLResponse {
            if let url = resp.url, let allHeaderFields = resp.allHeaderFields as? [String : String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
                for cookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
        }
        decisionHandler(.cancel)
        callback()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        NSLog("didCommit")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("error")
        if let urltoload = URL(string: TRACSClient.portalurl) {
            self.webView.load(URLRequest(url: urltoload))
        }
    }
}
