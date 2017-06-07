//
//  Utils.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit
import LocalAuthentication
import WebKit

class Utils {
    static let red = UIColor(red: 80/255.0, green: 18/255.0, blue: 20/255.0, alpha: 1)
    static let darkred = UIColor(red: 45/255.0, green: 9/255.0, blue: 14/255.0, alpha: 1)
    static let gold = UIColor(red: 140/255.0, green: 115/255.0, blue: 74/255.0, alpha: 1)
    static let darkblue = UIColor(red: 40/255.0, green: 40/255.0, blue: 59/255.0, alpha: 1)
    static let gray = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
    static let nearblack = UIColor(white: 0.15, alpha: 1)
    static let colordisabled = UIColor(white: 0.8, alpha: 0.2)
    static let urlsession = URLSession.shared
    static let userAgent = UIWebView().stringByEvaluatingJavaScript(from:"navigator.userAgent")! + " TRACS Mobile"
    private static let wkprocesspool = WKProcessPool()
    private static let post_queue = DispatchGroup()
    private static var indicators:[Int:UIActivityIndicatorView] = [:]
    private static var user = ""
    private static var pw = ""
    private static var longterm = false
    
    static func isSimulator()->Bool {
        #if arch(i386) || arch(x86_64)
            return true
        #else
            return false
        #endif
    }
    
    // MARK: - UserDefaults
    static func save(_ obj:Any, withKey:String) {
        if let codingobj = obj as? NSCoding {
            let data = NSKeyedArchiver.archivedData(withRootObject: codingobj)
            UserDefaults.standard.set(data, forKey: withKey)
        } else {
            NSLog("was asked to save an object (key: %@) that does not conform to NSCoding!", withKey)
        }
    }
    
    static func grab(_ withKey:String) -> Any? {
        var ret:Any? = nil
        if let data = UserDefaults.standard.data(forKey: withKey) {
            ret = NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return ret
    }
    
    static func zap(_ key:String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    static func flag(_ key:String, val:Bool) -> Bool {
        let current = grab(key) as? Bool ?? false
        save(val, withKey: key)
        return current
    }
    
    // MARK: - HTTP Helpers
    static func getWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        return getWebView(config: config)
    }
    
    static func getWebView(config:WKWebViewConfiguration) -> WKWebView {
        if #available(iOS 10.0, *) {
            config.ignoresViewportScaleLimits = true
        }
        config.processPool = Utils.wkprocesspool
        return WKWebView(frame: CGRect.zero, configuration: config)
    }

    private static func standardRequest(_ url: URL)->URLRequest {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if url.absoluteString.contains(IntegrationClient.baseurl) {
            req.setValue(IntegrationClient.deviceToken, forHTTPHeaderField: "X-Notification-Device-Token")
        }
        return req
    }

    static func fetch(_ url:String, completion:@escaping (String)->Void) {
        if let targeturl = URL(string: url) {
            var req = standardRequest(targeturl)
            req.cachePolicy = .reloadIgnoringLocalCacheData
            urlsession.dataTask(with: req, completionHandler: { (data, response, error) in
                if let data = data {
                    let ret = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(ret)
                } else {
                    completion("")
                }
            }).resume()
        } else {
            completion("")
        }
    }
    
    static func fetchJSON(url:String, completion:@escaping (Any?)->Void) {
        // fake data for testing
        let targeturl = URL(string: url)
        var req = standardRequest(targeturl!)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        urlsession.dataTask(with:req) { (data, response, error) in
            if error != nil {
                NSLog("%@", error?.localizedDescription ?? "")
                return completion(nil)
            }
            if let data = data {
                //NSLog("%@: %@", url, String(data: data, encoding: .utf8) ?? "nil")
                if let parsed = try? JSONSerialization.jsonObject(with: data, options: []) {
                    return completion(parsed);
                } else {
                    NSLog("was not able to parse json from %@", url)
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
    
    static func post(url: String, jsonobject:[String:Any], completion:@escaping(Any?, Bool)->Void) {
        if let body = JSON.toJSON(jsonobject) {
            post(url: url, body: body, completion: completion)
        } else {
            NSLog("badly formatted jsonobject handed to post(jsonobject:)")
            completion(nil, false)
        }
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
                if !success {
                    NSLog("received a failing status code during post: %i", httpresponse.statusCode)
                    return completion(nil, false)
                }
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
    
    static func patch(url:String, jsonobject:[String:Any], completion:@escaping(Bool)->Void) {
        var request = standardRequest(URL(string: url)!)
        request.httpMethod = "PATCH"
        request.httpBody = JSON.toJSON(jsonobject)?.data(using: .utf8)
        urlsession.dataTask(with: request) { (data, resp, error) in
            if error != nil {
                NSLog("patch error url=%@, error=%@", url, error!.localizedDescription)
                completion(false)
            } else if let httpresp = resp as? HTTPURLResponse {
                if httpresp.statusCode >= 200 && httpresp.statusCode < 300 {
                    completion(true)
                } else {
                    let body = String(data: request.httpBody!, encoding: .utf8)
                    let respbody = String(data: data!, encoding: .utf8)
                    NSLog("patch failed url=%@ requestBody=%@ statusCode=%i responseBody=%@", url, body ?? "nil", httpresp.statusCode, respbody ?? "nil")
                    completion(false)
                }
            } else {
                NSLog("response was not an HTTPURLResponse")
                completion(false)
            }
        }.resume()
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
    
    static func logCookieStore() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                NSLog("logCookieStore: %@", cookie)
            }
        }
    }
    
    static func logCookieStore(forurl:String) {
        if let url = URL(string: forurl) {
            if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
                for cookie in cookies {
                    NSLog("logCookieStore: %@", cookie)
                }
            }
        }
    }
    
    // MARK: - UI Helpers
    
    static func alert(vc: UIViewController, message:String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func boldPreferredFont(style:UIFontTextStyle) -> UIFont {
        let font = UIFont.preferredFont(forTextStyle: style)
        return UIFont.boldSystemFont(ofSize: font.pointSize)
    }
    
    static func fontAwesomeBarButtonItem(icon: FontAwesome, target: AnyObject, action: Selector) -> UIBarButtonItem {
        let ret = UIBarButtonItem(title: " "+String.fontAwesomeIcon(name: icon)+" ", style: UIBarButtonItemStyle.plain, target: target, action: action)
        ret.setTitleTextAttributes([NSFontAttributeName: UIFont.fontAwesome(ofSize: 28)], for: .normal)
        return ret
    }
    
    static func fontAwesomeBadgedBarButtonItem(color: UIColor, badgecount: Int, icon: FontAwesome, target: AnyObject, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        button.titleEdgeInsets = UIEdgeInsets.init(top: 5, left: 10, bottom: 15, right: 10)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.titleLabel?.font = UIFont.fontAwesome(ofSize: 28)
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(colordisabled, for: .disabled)
        button.setTitle(String.fontAwesomeIcon(name: icon), for: .normal)
        if badgecount > 0 {
            let font = UIFont.preferredFont(forTextStyle: .footnote)
            let s = (String(badgecount) as NSString).size(attributes: [
                NSFontAttributeName: font
                ])
            let badge = BadgeSwift(frame:CGRect(x: 0, y: 0, width: s.width+10, height: s.height))
            badge.font = font
            badge.textColor = UIColor.white
            badge.text = String(badgecount)
            badge.badgeColor = darkred
            button.addSubview(badge)
        }
        let ret = UIBarButtonItem(customView: button)
        return ret;
    }
    
    static func fontAwesomeTitledBarButtonItem(color: UIColor, icon: FontAwesome, title:String, textStyle:UIFontTextStyle, target:AnyObject, action:Selector) -> UIBarButtonItem {
        let icon = UIImageView(image: UIImage.fontAwesomeIcon(name: icon, textColor: color, size: CGSize(width: 34, height: 34)))
        icon.frame = CGRect(x: 0, y: 3, width: 34, height: 34)
        icon.contentMode = .center
        
        let titlelabel = UILabel()
        titlelabel.text = title
        titlelabel.font = UIFont.boldSystemFont(ofSize: 20)
        titlelabel.sizeToFit()
        titlelabel.frame = CGRect(x: icon.bounds.width+2, y: (42-titlelabel.frame.height)/2.0, width: titlelabel.frame.width, height: titlelabel.frame.height)
        titlelabel.textColor = color
        
        let titleview = UIButton(frame: CGRect(x: 0, y: 0, width: titlelabel.frame.origin.x+titlelabel.frame.width, height: 50))
        titleview.accessibilityLabel = title
        titleview.addSubview(icon)
        titleview.addSubview(titlelabel)
        
        titleview.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: titleview)
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
    static func store(netid:String, pw:String, longterm:Bool) {
        Utils.user = netid
        Utils.pw = pw
        Utils.longterm = longterm
        if longterm {
            save(longterm, withKey: "longterm")
            save(Date(), withKey: "logintime")
            save(netid, withKey: "netid")
            KeychainSwift.shared.set(pw, forKey: "password")
        }
    }
    static func extendedlogin()->Bool {
        if netidExpired() { return false }
        return grab("longterm") as? Bool ?? false
    }
    static func haveCredentials()->Bool {
        return !netid().isEmpty && !password().isEmpty
    }
    static func removeCredentials() {
        user = ""
        pw = ""
        zap("logintime")
        zap("netid")
        KeychainSwift.shared.delete("password")
    }
    static func netidExpired() -> Bool {
        if let logintime = grab("logintime") as? Date {
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
        if !user.isEmpty { return user }
        if netidExpired() { return "" }
        return grab("netid") as? String ?? ""
    }
    static func password() -> String {
        if !pw.isEmpty { return pw }
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
    
    // MARK: - Date math
    static func date(_ d:Date, isNewerThan:Int, units:Calendar.Component) -> Bool {
        return d > Calendar.current.date(byAdding: units, value: -isNewerThan, to: Date())!
    }
    static func date(_ d:Date, isOlderThan:Int, units:Calendar.Component) -> Bool {
        return !date(d, isNewerThan: isOlderThan, units: units)
    }
    
    // MARK: - Other Utilities
    static func randomHexString(length: Int) -> String {
        
        let letters : NSString = "0123456789abcdef"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}
