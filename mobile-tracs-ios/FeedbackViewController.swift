//
//  FeedbackViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/14/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class FeedbackViewController: UIViewController {

    @IBOutlet var sendButton:UIButton!
    @IBOutlet var reviewButton:UIButton!
    @IBOutlet var textView:UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sendButton.addTarget(self, action: #selector(pressedSend), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(pressedReview), for: .touchUpInside)
    }
    
    func pressedSend() {
        
    }
    func pressedReview() {
        let appId = "YOUR_APP_ID"
        let url_string = "itms-apps://itunes.apple.com/app/id\(appId)"
        if let url = URL(string: url_string) {
            UIApplication.shared.openURL(url)
        }
    }
}
