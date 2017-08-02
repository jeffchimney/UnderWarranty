//
//  SignUpViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-01-05.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var iconImageView: UIImageView!
    
    var signingIn: Bool!
    var timesSignUpPressed = 0
    var timesSignInPressed = 0
    
    var username = ""
    var password = ""
    
    var originalFrame = CGRect()
    
    override func viewDidLoad() {
        errorLabel.isHidden = true
        indicator.isHidden = true
        
        usernameField.delegate = self
        passwordField.delegate = self
        
        if signingIn! {
            signInButton.setTitle("Sign In", for: .normal)
        } else {
            signInButton.setTitle("Sign Up", for: .normal)
        }
        
         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        originalFrame = iconImageView.frame
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        indicator.isHidden = false
        indicator.startAnimating()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        username = usernameField.text!
        password = passwordField.text!
        
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        if !signingIn! { // (signing up) create new username password combo and save to cloud and locally
            
            errorLabel.text = "Creating Account..."
            errorLabel.textColor = .black
            errorLabel.isHidden = false
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let accountEntity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
            //let account = NSManagedObject(entity: accountEntity, insertInto: managedContext) as! Account
        
            let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
            let accountRecord = CKRecord(recordType: "Accounts")
            
            let dateCreated = Date() as NSDate
            
            accountRecord.setValue(username, forKey: "username")
            accountRecord.setValue(password, forKey: "password")
            accountRecord.setValue(dateCreated, forKey: "lastSynced")
            
            
            let predicate = NSPredicate(format: "username = %@", argumentArray: [usernameField.text!])
            
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.errorLabel.text = "Connection error. Try again later."
                        self.errorLabel.textColor = .red
                        self.errorLabel.isHidden = false
                        self.indicator.isHidden = true
                        self.indicator.stopAnimating()
                    }
                } else {
                    if (results?.count)! > 0 { // username already exists
                        DispatchQueue.main.async {
                            self.errorLabel.text = "That username is already in use."
                            self.errorLabel.textColor = .red
                            self.errorLabel.isHidden = false
                            self.indicator.isHidden = true
                            self.indicator.stopAnimating()
                        }
                        return // don't go any further.
                    } else {
                        // save to the cloud
                        publicDatabase.save(accountRecord, completionHandler: { (record, error) in
                            if error != nil {
                                DispatchQueue.main.async {
                                    self.errorLabel.text = "Connection error. Try again later."
                                    self.errorLabel.textColor = .red
                                    self.errorLabel.isHidden = false
                                    self.indicator.isHidden = true
                                    self.indicator.stopAnimating()
                                }
                                return
                            } else {
                                //account.username = self.usernameField.text
                                //account.password = self.passwordField.text
                                //account.id = accountRecord.recordID.recordName
                            }
                        })
                        
                        // save locally
                        do {
                            try managedContext.save()
                        } catch {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Connection error. Try again later."
                                self.errorLabel.textColor = .red
                                self.errorLabel.isHidden = false
                                self.indicator.isHidden = true
                                self.indicator.stopAnimating()
                            }
                            return
                        }
                        
                        // set userdefaults for first launch
                        let defaults = UserDefaults.standard
                        defaults.set(false, forKey: "FirstLaunch")
                        defaults.set(self.username, forKey: "username")
                        defaults.set(self.password, forKey: "password")
                        defaults.set(false, forKey: "SyncUsingData")
                        defaults.set(true, forKey: "SignedIn")
                        
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "unwindToInitial", sender: nil)
                        }
                    }
                }
            })
            
        } else { // fetch existing username/password combo and save locally
            let managedContext = appDelegate.persistentContainer.viewContext
            let accountEntity = NSEntityDescription.entity(forEntityName: "Account", in: managedContext)!
            //let account = NSManagedObject(entity: accountEntity, insertInto: managedContext) as! Account
            
            let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
            let predicate = NSPredicate(format: "username = %@ AND password = %@", usernameField.text!, passwordField.text!)
            let query = CKQuery(recordType: "Accounts", predicate: predicate)
            
            errorLabel.text = "Signing in..."
            errorLabel.textColor = .black
            errorLabel.isHidden = false
            
            publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.errorLabel.text = "Connection error. Try again later."
                        self.errorLabel.textColor = .red
                        self.errorLabel.isHidden = false
                        self.indicator.isHidden = true
                        self.indicator.stopAnimating()
                    }
                    return
                } else {
                    if (results?.count)! < 1 {
                        DispatchQueue.main.async { // show error, incorrect username password combo
                            self.errorLabel.text = "Incorrect username or password."
                            self.errorLabel.textColor = .red
                            self.errorLabel.isHidden = false
                            self.indicator.isHidden = true
                            self.indicator.stopAnimating()
                        }
                        return
                    } else { // save the username and password locally and log in
                        //account.username = self.usernameField.text
                        //account.password = self.passwordField.text
                        //account.id = results?[0].recordID.recordName
                        
                        // save locally
                        do {
                            try managedContext.save()
                        } catch {
                            DispatchQueue.main.async {
                                self.errorLabel.text = "Connection error. Try again later."
                                self.errorLabel.textColor = .red
                                self.errorLabel.isHidden = false
                                self.indicator.isHidden = true
                                self.indicator.stopAnimating()
                            }
                            return
                        }
                        
                        // set userdefaults for first launch
                        let defaults = UserDefaults.standard
                        defaults.set(false, forKey: "FirstLaunch")
                        defaults.set(self.username, forKey: "username")
                        defaults.set(self.password, forKey: "password")
                        defaults.set(false, forKey: "SyncUsingData")
                        defaults.set(true, forKey: "SignedIn")
                        
                        DispatchQueue.main.async {
                            self.errorLabel.text = "Retrieving existing records..."
                            self.errorLabel.textColor = .black
                            self.errorLabel.isHidden = false
                            self.getAllCloudKitRecordsWith(associatedAccount: (results?[0])!)
                        }
                    }
                }
            })
        }
    }
    
    func getAllCloudKitRecordsWith(associatedAccount: CKRecord) {
        // cloudkit
        let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "AssociatedAccount = %@", associatedAccount.recordID)
        let query = CKQuery(recordType: "Records", predicate: predicate)
        // coredata
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext)!

        
        publicDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print(error.debugDescription)
                DispatchQueue.main.async {
                    self.errorLabel.text = "Error retrieving records."
                    self.errorLabel.textColor = .red
                    self.errorLabel.isHidden = false
                    self.indicator.isHidden = true
                    self.indicator.stopAnimating()
                }
                return
            } else {
                for result in results! {
                    let record = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
                    //hello
                    record.recordID = result.recordID.recordName
                    record.dateCreated = result.value(forKey: "dateCreated") as! NSDate?
                    record.dateDeleted = result.value(forKey: "dateDeleted") as! NSDate?
                    record.daysBeforeReminder = result.value(forKey: "daysBeforeReminder") as! Int32
                    record.descriptionString = result.value(forKey: "descriptionString") as! String?
                    record.eventIdentifier = result.value(forKey: "eventIdentifier") as! String?
                    record.title = result.value(forKey: "title") as! String?
                    record.warrantyStarts = result.value(forKey: "warrantyStarts") as! NSDate?
                    record.warrantyEnds = result.value(forKey: "warrantyEnds") as! NSDate?
                    // CKAssets need to be converted to NSData
                    //let itemImage = result.value(forKey: "itemData") as! CKAsset
                    //record.itemImage = NSData(contentsOf: itemImage.fileURL)
                    //let receiptImage = result.value(forKey: "receiptData") as! CKAsset
                    //record.receiptImage = NSData(contentsOf: receiptImage.fileURL)
                    // Bools stored as ints on CK.  Need to be converted
                    let recentlyDeleted = result.value(forKey: "recentlyDeleted") as! Int64
                    if recentlyDeleted == 0 {
                        record.recentlyDeleted = false
                    } else {
                        record.recentlyDeleted = true
                    }
                    let expired = result.value(forKey: "expired") as! Int64
                    if expired == 0 {
                        record.expired = false
                    } else {
                        record.expired = true
                    }
                    let hasWarranty = result.value(forKey: "hasWarranty") as! Int64
                    if hasWarranty == 0 {
                        record.hasWarranty = false
                    } else {
                        record.hasWarranty = true
                    }
                    
                    // save locally
                    do {
                        try managedContext.save()
                        CoreDataHelper.importImagesFromCloudKit(associatedWith: record, in: managedContext)
                        CoreDataHelper.importNotesFromCloudKit(associatedWith: record, in: managedContext)
                    } catch {
                        DispatchQueue.main.async {
                            self.errorLabel.text = "Connection error. Try again later."
                            self.errorLabel.textColor = .red
                            self.errorLabel.isHidden = false
                            self.indicator.isHidden = true
                            self.indicator.stopAnimating()
                        }
                        return
                    }
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "unwindToInitial", sender: nil)
                }
            }
        })
    }
    
    //MARK: Text Field Delegate Methods
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if usernameField.text != "" && passwordField.text != "" {
            
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        //
        let nextTag=textField.tag+1;
        // Try to find next responder
        let nextResponder=textField.superview?.viewWithTag(nextTag) as UIResponder!
        
        if (nextResponder != nil){
            // Found next responder, so set it.
            nextResponder?.becomeFirstResponder()
        }
        else
        {
            // trigger sign in
            signInButton.sendActions(for: .touchUpInside)
            // Not found, so remove keyboard
            textField.resignFirstResponder()
        }
        return false // We do not want UITextField to insert line-breaks.
    }
    
    func keyboardWillShow(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        print(keyboardHeight)
//        UIView.animate(withDuration: 0.5, animations: {
//            self.iconImageView.center = CGPoint(x: self.iconImageView.center.x, y: self.iconImageView.center.y-keyboardHeight)
//        })
    }
}
