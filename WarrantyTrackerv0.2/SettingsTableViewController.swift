//
//  SettingsTableViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-02-19.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData
import EventKit
import AVFoundation
import StoreKit
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var allowCameraAccessLabel: UILabel!
    @IBOutlet weak var allowCalendarAccessLabel: UILabel!
    @IBOutlet weak var rateUnderWarantyLabel: UILabel!
    @IBOutlet weak var rateUnderWarrantySubTitle: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var cameraSwitch: UISwitch!
    @IBOutlet weak var calendarSwitch: UISwitch!
    @IBOutlet weak var contactDeveloperLabel: UILabel!
    let eventStore = EKEventStore()
    
    override func viewDidLoad() {
        
//        allowCameraAccessLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
//        allowCalendarAccessLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
//        rateUnderWarantyLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
//        contactDeveloperLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        
    }
    
    override func viewDidLayoutSubviews() {
        if EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
            calendarSwitch.isOn = true
        } else {
            calendarSwitch.isOn = false
        }
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized {
            cameraSwitch.isOn = true
        } else {
            cameraSwitch.isOn = false
        }
//        if UserDefaultsHelper.canSyncUsingData() {
//            allowDataSyncSwitch.isOn = true
//        } else {
//            allowDataSyncSwitch.isOn = false
//        }
//        if UserDefaultsHelper.syncEnabled() {
//            allowSync.isOn = true
//        } else {
//            allowSync.isOn = false
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // ask for camera permissions if not already set
        if(UserDefaults.standard.value(forKey: "CameraPermissions") == nil) {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    // User granted
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: true)
                        self.cameraSwitch.isOn = true
                    }
                }
                else
                {
                    // User Rejected
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: false)
                        self.cameraSwitch.isOn = true
                    }
                }
            });
        }
        
        // ask for calendar permissions if not already set
        if(UserDefaults.standard.value(forKey: "CalendarPermissions") == nil) {
            eventStore.requestAccess(to: EKEntityType.event, completion: {
                (accessGranted: Bool, error: Error?) in
                
                if accessGranted == true {
                    UserDefaultsHelper.setCalendarPermissions(to: true)
                    DispatchQueue.main.async(execute: {
                        self.calendarSwitch.isOn = true
                    })
                } else {
                    UserDefaultsHelper.setCalendarPermissions(to: false)
                    DispatchQueue.main.async(execute: {
                        self.calendarSwitch.isOn = false
                    })
                }
            })
        }
    }
    
    @IBAction func cameraAccessSwitch(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    @IBAction func calendarAccessSwitch(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Permissions"
        case 1:
            return ""
        case 2:
            return "Feedback"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            rateApp(appId: "id1091944550", completion: { linked in
                print(linked)
            })
        } else if indexPath.section == 1 && indexPath.row == 1 {
            if !MFMailComposeViewController.canSendMail() {
                print("Mail services are not available")
                return
            }
            sendEmail()
        }
    }
    
    func rateApp(appId: String, completion: @escaping ((_ success: Bool)->())) {
        guard let url = URL(string : "itms-apps://itunes.apple.com/app/" + appId) else {
            completion(false)
            return
        }
        guard #available(iOS 10, *) else {
            completion(UIApplication.shared.openURL(url))
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
    
//    @IBAction func deleteLocalStorageButtonPressed(_ sender: Any) {
//        let alertController = UIAlertController(title: "You Sure?", message: "UnderWarranty uses iCloud to back up and sync your Warranties.  Do you want to delete your local storage? (Any records in the cloud will be retrieved when you pull to refresh table view on the main page if there are no records in your local storage)", preferredStyle: UIAlertControllerStyle.alert)
//
//        // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
//        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
//            (result : UIAlertAction) -> Void in
//            print("Cancel")
//        }
//
//        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.destructive) {
//            (result : UIAlertAction) -> Void in
//            print("Delete")
//
//            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
//                return
//            }
//
//            do {
//                let managedContext = appDelegate.persistentContainer.viewContext
//
//                let fetchNote = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
//                let requestNote = NSBatchDeleteRequest(fetchRequest: fetchNote)
//                _ = try managedContext.execute(requestNote)
//
//                let fetchImage = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
//                let requestImage = NSBatchDeleteRequest(fetchRequest: fetchImage)
//                _ = try managedContext.execute(requestImage)
//
//                let fetchRecord = NSFetchRequest<NSFetchRequestResult>(entityName: "Record")
//                let requestRecord = NSBatchDeleteRequest(fetchRequest: fetchRecord)
//                _ = try managedContext.execute(requestRecord)
//            } catch {
//                print("Failed to delete everything in core data")
//            }
//        }
//
//        alertController.addAction(cancelAction)
//        alertController.addAction(deleteAction)
//        self.present(alertController, animated: true, completion: nil)
//    }
    
    func sendEmail() {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        // Configure the fields of the interface.
        composeVC.setToRecipients(["underwarrantyfeedback@gmail.com"])
        composeVC.setSubject("Feedback")
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
