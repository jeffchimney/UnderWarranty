//
//  AccountQuestionViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-05.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AccountQuestionViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var infoButton: UIButton!
    var signingIn = false
    
    override func viewDidLoad() {
        UserDefaultsHelper.setCameraPermissions(to: false)
        UserDefaultsHelper.setCalendarPermissions(to: false)
    }
    
    @IBAction func skipButtonPressed(_ sender: UIButton) {
        // set userdefaults for first launch
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: "FirstLaunch")
        defaults.set(false, forKey: "SyncUsingData")
        defaults.set(false, forKey: "SignedIn")
        
        performSegue(withIdentifier: "unwindToInitialController", sender: nil)
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        signingIn = true
        
        self.performSegue(withIdentifier: "toSignUpController", sender: nil)
    }
    
    @IBAction func noButtonPressed(_ sender: UIButton) {
        signingIn = false
        
        self.performSegue(withIdentifier: "toSignUpController", sender: nil)
    }
    
    @IBAction func infoButtonPressed(_ sender: UIButton) {
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "whySignUp") as! WhySignUpController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = infoButton
        popController.popoverPresentationController?.sourceRect = CGRect(x: self.infoButton.bounds.midX, y: self.infoButton.bounds.maxY, width: 0, height: 0)

        // present the popover
        popoverPresentationController?.delegate = self
        self.present(popController, animated: true, completion: nil)
    }

    // popover delegate methods
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSignUpController") {
            if let nextViewController = segue.destination as? SignUpViewController {
                nextViewController.signingIn = signingIn
            }
        }
    }
}
