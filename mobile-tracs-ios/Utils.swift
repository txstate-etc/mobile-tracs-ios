//
//  Utils.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 3/18/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class Utils {
    static let red = UIColor(red: 80/255.0, green: 18/255.0, blue: 20/255.0, alpha: 1)
    static let darkred = UIColor(red: 45/255.0, green: 9/255.0, blue: 14/255.0, alpha: 1)
    static let gold = UIColor(red: 140/255.0, green: 115/255.0, blue: 74/255.0, alpha: 1)
    static let darkblue = UIColor(red: 40/255.0, green: 40/255.0, blue: 59/255.0, alpha: 1)
    static let lightgray = UIColor(red: 229/255.0, green: 232/255.0, blue: 227/255.0, alpha: 1)
    static let lightergray = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)

    static func constrainToContainer(view: UIView, container: UIView) {
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0.0))
        container.addConstraint(NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: container, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0.0))
    }
    
    static func fetchJSON(url:String, completion:@escaping ([String:Any]?)->Void) {
        let targeturl = URL(string: url)
        URLSession.shared.dataTask(with:targeturl!) { (data, response, error) in
            if error != nil {
                NSLog("%@", error?.localizedDescription ?? "")
                return completion(nil)
            }
            if data != nil {
                let parsed = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                if parsed != nil {
                    completion(parsed);
                }
            }
            completion(nil)
        }
    }
    
    static func paramsToString(params:[String:String])->String {
        var pairs: [String] = []
        for (key,value) in params {
            pairs.append(key.addingPercentEncoding(withAllowedCharacters: [])!+"="+value.addingPercentEncoding(withAllowedCharacters: [])!)
        }
        return pairs.joined(separator: "&")
    }
    
    static func post(url: String, params: [String:String], completion:@escaping(Any?, Bool)->Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        let body = paramsToString(params: params)
        request.httpBody = body.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                NSLog("could not post %@", error!.localizedDescription)
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
    
    static func delete(url: String, params: [String:String], completion:@escaping(Any?,Bool)->Void) {
        let withquery = url+"?"+paramsToString(params: params)
        var request = URLRequest(url: URL(string: withquery)!)
        request.httpMethod = "DELETE"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
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
    
    static func alert(vc: UIViewController, message:String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
}
