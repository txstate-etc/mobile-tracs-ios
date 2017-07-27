//
//  LoginViewController.swift
//  mobile-tracs-ios
//
//  Created by Andrew Thyng on 7/12/17.
//  Copyright © 2017 Texas State University. All rights reserved.
//

import Foundation

class LoginViewController : UIViewController, UITextFieldDelegate,UIGestureRecognizerDelegate {
    //MARK: Properties
    @IBOutlet weak var loginNetid: LoginTextField!
    @IBOutlet weak var loginPassword: LoginTextField!
    @IBOutlet weak var loginLogoImage: LoginLogoImage!
    @IBOutlet weak var loginScrollView: UIScrollView!
    @IBOutlet weak var loginSubmitButton: LoginButton!
    @IBOutlet weak var loginAdvisory: AdvisoryLabel!
    @IBOutlet var viewTap: UIView!
    
    let loginAdvisoryText = "Use of computer and network facilities owned or operated by Texas State University requires prior authorization. Unauthorized access is prohibited. Usage may be subject to security testing and monitoring, and affords no privacy guarantees or expectations except as otherwise provided by applicable privacy laws. Abuse is subject to criminal prosecution. Use of these facilities implies agreement to comply with the policies of Texas State University."
    
    var activeField: UITextField?
    var keyboardDismissTouch = UITapGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginNetid.delegate = self
        loginPassword.delegate = self
        loginSubmitButton.addTarget(self, action: #selector(onLoginPress), for: .touchUpInside)
        
        //Keyboard dismissal setup when tapping outside text boxes
        keyboardDismissTouch = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        keyboardDismissTouch.delegate = self
        loginScrollView.addGestureRecognizer(keyboardDismissTouch)
        
        //Keyboard show and hide notification registrations
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //Advisory text setup
        loginAdvisory.text = loginAdvisoryText
        
        //ScrollView Sizing
//        loginScrollView.sizeToFit()
//        loginScrollView.contentSize = CGSize(width: loginScrollView.frame.width, height: loginAdvisory.frame.height + loginScrollView.frame.height)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
        
    func onLoginPress(sender: UIButton!) {
        sendLoginRequest()
    }
    

    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        switch textField.returnKeyType {
        case UIReturnKeyType.next:
            let nextTag = textField.tag + 1
            if let nextResponder = textField.superview?.viewWithTag(nextTag) as UIResponder! {
                nextResponder.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        case UIReturnKeyType.send:
            sendLoginRequest()
            break
        default:
            break
            //no action
        }

        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        textField.becomeFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
        textField.resignFirstResponder()
    }
    
    //MARK: Keyboard Event Handlers
    func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let kbSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
            let contentInsets = UIEdgeInsetsMake(0.0, 0.0, (kbSize?.height)!, 0.0)
            loginScrollView.contentInset = contentInsets
            loginScrollView.scrollIndicatorInsets = contentInsets
            
            self.loginScrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        loginScrollView.contentInset = contentInsets
        loginScrollView.scrollIndicatorInsets = contentInsets
        loginScrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    //MARK: TapGestureRecognizer
    func dismissKeyboard(_ sender: UITapGestureRecognizer? = nil) {
        self.view.endEditing(true)
    }
    
    //MARK: Private Methods
    private func sendLoginRequest() {
        Utils.removeCredentials()
        Utils.store(netid: loginNetid.text!, pw: loginPassword.text!, longterm: true)
        DispatchQueue.main.async {
            Utils.showActivity(self.view)
        }
        IntegrationClient.saveRegistration(reg: IntegrationClient.getRegistration(), password: self.loginPassword.text!, completion: { (registered) in
            NSLog("Registration was \(registered ? "successful" : "not successful")")
            TRACSClient.loginIfNecessary(completion: { (loggedIn) in
                if loggedIn {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    DispatchQueue.main.async {
                        UIAlertView(title: "Login Failure", message: "Could not login to TRACS", delegate: nil, cancelButtonTitle: "OK").show()
                        Utils.hideActivity()
                    }
                }
                
            })
        })
    }
}
