//
//  Utils.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import LocalAuthentication

class Utils {
    static let red = UIColor(red: 80/255.0, green: 18/255.0, blue: 20/255.0, alpha: 1)
    static let darkred = UIColor(red: 45/255.0, green: 9/255.0, blue: 14/255.0, alpha: 1)
    static let gold = UIColor(red: 140/255.0, green: 115/255.0, blue: 74/255.0, alpha: 1)
    static let darkblue = UIColor(red: 40/255.0, green: 40/255.0, blue: 59/255.0, alpha: 1)
    static let lightgray = UIColor(red: 229/255.0, green: 232/255.0, blue: 227/255.0, alpha: 1)
    static let lightergray = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)
    static let colordisabled = UIColor(white: 0.8, alpha: 0.2)
    static let urlsession = URLSession.shared
    internal static let post_queue = DispatchGroup()
    internal static var indicators:[Int:UIActivityIndicatorView] = [:]
    
    static func isSimulator()->Bool {
        #if arch(i386) || arch(x86_64)
            return true
        #endif
        return false
    }
    
    // MARK: - HTTP Helpers
    
    private static func standardRequest(_ url: URL)->URLRequest {
        var req = URLRequest(url: url)
        if url.absoluteString.contains(IntegrationClient.baseurl) {
            req.setValue(IntegrationClient.deviceToken, forHTTPHeaderField: "X-Notification-Device-Token")
        }
        return req
    }
    
    static func fetchJSON(url:String, completion:@escaping (Any?)->Void) {
        // fake data for testing
        if url.contains(IntegrationClient.notificationsurl) { return completion([[
                "keys":[
                    "provider_id":"tracs",
                    "notification_type":"creation",
                    "object_type": "announcement",
                    "object_id": "831342dd-fdb6-4878-8b3c-1d29ecb06a14:main:aa4f8f85-a645-4766-bc91-1a1c7bef93df",
                    "user_id": "392b6c67-e53f-4c47-8068-3602bdc7b782"
                ],
                "otherkeys":[
                    "site_id": "831342dd-fdb6-4878-8b3c-1d29ecb06a14"
                ],
                "content_hash": "hash",
                "notify_after": "2017-03-22T12:50:00-0500",
                "read": false,
                "cleared": false
                ]])
        }
        let targeturl = URL(string: url)
        var req = standardRequest(targeturl!)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        urlsession.dataTask(with:req) { (data, response, error) in
            if error != nil {
                NSLog("%@", error?.localizedDescription ?? "")
                return completion(nil)
            }
            if data != nil {
                NSLog("%@: %@", url, String(data: data!, encoding: .utf8) ?? "nil")
                do {
                    let parsed = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                    return completion(parsed);
                } catch {
                    NSLog(error.localizedDescription)
                }
            }
            return completion(nil)
        }.resume()
    }
    
    static func fetchJSONObject(url:String, completion:@escaping([String:Any]?)->Void) {
        fetchJSON(url: url) { (ret) in
            completion(ret as? [String:Any])
        }
    }
    
    static func fetchJSONArray(url:String, completion:@escaping([Any]?)->Void) {
        fetchJSON(url: url) { (ret) in
            completion(ret as? [Any])
        }
    }
    
    static func paramsToString(params:[String:String])->String {
        var pairs: [String] = []
        for (key,value) in params {
            pairs.append(key.addingPercentEncoding(withAllowedCharacters: [])!+"="+value.addingPercentEncoding(withAllowedCharacters: [])!)
        }
        return pairs.joined(separator: "&")
    }
    
    static func stringToParams(_ str:String)->[String:String] {
        var ret:[String:String] = [:]
        let pairs = str.components(separatedBy: "&")
        for pair in pairs {
            let entry = pair.components(separatedBy: "=")
            if let key = entry[0].removingPercentEncoding, let val = entry[1].removingPercentEncoding {
                ret[key] = val
            }
        }
        return ret
    }
    
    static func post(url: String, params:[String:String], completion:@escaping(Any?, Bool)->Void) {
        post(url: url, body: paramsToString(params: params), completion: completion)
    }
    
    static func post(url: String, body: String, completion:@escaping(Any?, Bool)->Void) {
        var request = standardRequest(URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        let task = urlsession.dataTask(with: request) { (data, response, error) in
            if error != nil {
                NSLog("could not post: %@", error!.localizedDescription)
                completion(nil, false)
                post_queue.leave()
                return
            }
            if response is HTTPURLResponse {
                let httpresponse = response as! HTTPURLResponse
                let success = httpresponse.statusCode >= 200 && httpresponse.statusCode < 300
                if data != nil {
                    let parsed = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if parsed != nil { return completion(parsed, success) }
                }
                if data != nil, let data = String(data:data!, encoding:.utf8) {
                    completion(data, success)
                } else {
                    completion(data, success)
                }
                post_queue.leave()
            }
        }
        post_queue.notify(queue: .main) { 
            post_queue.enter()
            task.resume()
        }
    }
    
    static func delete(url: String, params: [String:String], completion:@escaping(Any?,Bool)->Void) {
        let withquery = url+"?"+paramsToString(params: params)
        var request = standardRequest(URL(string: withquery)!)
        request.httpMethod = "DELETE"
        urlsession.dataTask(with: request) { (data, response, error) in
            if error != nil {
                NSLog("could not delete %@", error!.localizedDescription)
                return completion(nil, false)
            }
            if response is HTTPURLResponse {
                let httpresponse = response as! HTTPURLResponse
                let success = httpresponse.statusCode >= 200 && httpresponse.statusCode < 300
                if data != nil {
                    let parsed = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if parsed != nil { return completion(parsed, success) }
                }
                return completion(data, success)
            }
        }.resume()
    }
    
    // MARK: - UI Helpers
    
    static func alert(vc: UIViewController, message:String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func fontAwesomeBarButtonItem(icon: FontAwesome, target: AnyObject, action: Selector) -> UIBarButtonItem {
        let ret = UIBarButtonItem(title: String.fontAwesomeIcon(name: icon), style: UIBarButtonItemStyle.plain, target: target, action: action)
        ret.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 20)], for: .normal)
        return ret
    }
    
    static func fontAwesomeBadgedBarButtonItem(color: UIColor, badgecount: Int, icon: FontAwesome, target: AnyObject, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 34)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.titleLabel?.font = UIFont.fontAwesome(ofSize: 28)
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(colordisabled, for: .disabled)
        button.setTitle(String.fontAwesomeIcon(name: icon), for: .normal)
        if badgecount > 0 {
            let badge = BadgeSwift(frame:CGRect(x: 0, y: 0, width: 18, height: 18))
            badge.font = UIFont.preferredFont(forTextStyle: .footnote)
            //badge.insets = CGSize(width: 12, height: 12)
            badge.textColor = UIColor.white
            badge.text = String(badgecount)
            button.addSubview(badge)
        }
        let ret = UIBarButtonItem(customView: button)
        return ret;
    }
    
    static func constrainToContainer(view: UIView, container: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
    }
    
    static func constrainCentered(view: UIView, container: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
    }
    
    @discardableResult static func showActivity(_ inView:UIView) -> UIView {
        return showActivity(inView, withIndex:0)
    }
    
    @discardableResult static func showActivity(_ inView:UIView, withIndex:Int) -> UIView {
        // let's make sure the indicator isn't already animating
        hideActivity(withIndex)
    
        // create a view to grey out the entirety of the parent view we were given
        let actView = UIView()
        actView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    
        // create the indicator
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        // place the views where they go
        inView.addSubview(actView)
        constrainToContainer(view: actView, container: inView)
        actView.addSubview(indicator)
        constrainCentered(view: indicator, container: actView)
        
        indicator.startAnimating()
        indicators[withIndex] = indicator
        
        // we'll return actView in case our caller wants to create new views while
        // the indicator is going.  They'll need a view to use with [UIView insertBelow]
        return actView
    }
    
    static func hideActivity() {
        hideActivity(0)
    }
    
    static func hideActivity(_ index:Int) {
        if let indicator = indicators[index] {
            indicator.stopAnimating()
            indicator.superview?.removeFromSuperview()
            indicator.removeFromSuperview()
            indicators.removeValue(forKey: index)
        }
    }
    
    // MARK: - Login Credentials
    static func store(netid:String, pw:String) {
        UserDefaults.standard.set(Date(), forKey: "logintime")
        UserDefaults.standard.set(netid, forKey: "netid")
        KeychainSwift.shared.set(pw, forKey: "password")
    }
    static func haveCredentials()->Bool {
        return !netid().isEmpty && !password().isEmpty
    }
    static func removeCredentials() {
        UserDefaults.standard.removeObject(forKey: "logintime")
        UserDefaults.standard.removeObject(forKey: "netid")
        KeychainSwift.shared.delete("password")
    }
    static func netidExpired() -> Bool {
        let logintime = UserDefaults.standard.value(forKey: "logintime")
        if let logintime = logintime as? Date {
            var interval = DateComponents()
            if deviceIsLocked() {
                interval.month = 3
            } else {
                interval.day = 1
            }
            let expires = Calendar.current.date(byAdding: interval, to: logintime)
            if expires! > Date() { return false }
        }
        return true
    }
    static func netid() -> String {
        if netidExpired() { return "" }
        return UserDefaults.standard.value(forKey: "netid") as? String ?? ""
    }
    static func password() -> String {
        if netidExpired() { return "" }
        return KeychainSwift.shared.get("password") ?? ""
    }
    
    static func deviceIsLocked() -> Bool {
        if #available(iOS 9, *) {
            return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        } else if #available(iOS 8, *) {
            let secret = "Device has passcode set?".data(using: String.Encoding.utf8, allowLossyConversion: false)
            let attributes:[String:Any] = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: "LocalDeviceServices",
                kSecAttrAccount as String: "NoAccount",
                kSecValueData as String: secret!,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            ]
            
            let status = SecItemAdd(attributes as CFDictionary, nil)
            if status == 0 {
                SecItemDelete(attributes as CFDictionary)
                return true
            }
            
            return false
        }
        return false
    }
}
