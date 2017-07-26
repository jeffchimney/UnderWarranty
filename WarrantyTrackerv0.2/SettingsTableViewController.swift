//
//  SettingsTableViewController.swift
//  WarrantyTrackerv0.2
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

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var allowDataSyncLabel: UILabel!
    @IBOutlet weak var allowCameraAccessLabel: UILabel!
    @IBOutlet weak var allowCalendarAccessLabel: UILabel!
    @IBOutlet weak var rateUnderWarantyLabel: UILabel!
    @IBOutlet weak var rateUnderWarrantySubTitle: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var cameraSwitch: UISwitch!
    @IBOutlet weak var calendarSwitch: UISwitch!
    
    override func viewDidLoad() {
        
        usernameLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        allowDataSyncLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        allowCameraAccessLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        allowCalendarAccessLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        rateUnderWarantyLabel.defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        
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
    }
    
    override func viewDidLayoutSubviews() {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "username")
        
        if username != nil { // user is logged in
            
        }
        
        let toggleRow = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! TitleAndSwitchTableViewCell
        toggleRow.toggle.isOn = UserDefaultsHelper.canSyncUsingData()
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
            return "Feedback"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
