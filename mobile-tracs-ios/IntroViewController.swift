//
//  IntroViewController.swift
//  mobile-tracs-ios
//
//  Created by Nick Wing on 5/16/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    @IBOutlet var okButton:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        okButton.addTarget(self, action: #selector(okPressed), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func okPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
