//
//  WarrantyBeginsEndsViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import EventKit

class WarrantyBeginsEndsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // variables that have been passed forward
    var titleString: String! = nil
    var descriptionString: String! = nil
    var itemImageData: [Data?] = []
    //var receiptImageData: Data! = nil
    //
    
    @IBOutlet weak var beginsPicker: UIDatePicker!
    @IBOutlet weak var endsPicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var selectedStartDate: UILabel!
    @IBOutlet weak var selectedEndDate: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    //@IBOutlet weak var numberOfWeeksSegment: UISegmentedControl!
    @IBOutlet weak var daysBeforePicker: UIPickerView!
    @IBOutlet weak var lifetimeWarrantySwitch: UISwitch!
    @IBOutlet var cellsReliantOnEndDate: [UITableViewCell]!
    @IBOutlet weak var beginsCell: UITableViewCell!
    var startDatePicked = false
    var endDatePicked = false
    var hasWarranty = true
    var pickerData: [String] = []
    var navBarHeight: CGFloat!
    
    let defaults = UserDefaults.standard
    let eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    
    var selectedIndexPathRow = 0
    var beginsCellIsShowing = true
    var endsCellIsShowing = true
    
    var originalCellHeights: [CGFloat] = [44, 140, 44, 44, 140, 44, 100, 44]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginsPicker.datePickerMode = UIDatePickerMode.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        selectedStartDate.text = dateFormatter.string(from: beginsPicker.date)
        selectedStartDate.textColor = tableView.tintColor
        selectedEndDate.text = dateFormatter.string(from: endsPicker.date)
        selectedEndDate.textColor = tableView.tintColor

        navBar.title = "Warranty"
        
        for index in 1...31 {
            pickerData.append(String(index))
        }
        
        daysBeforePicker.delegate = self
        
        lifetimeWarrantySwitch.isOn = false
        
        navBarHeight = navigationController!.navigationBar.frame.height
        navigationController?.isToolbarHidden = true
        
        if !UserDefaultsHelper.hasCalendarPermissions() {
            requestAccessToCalendar()
        }
        
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        daysBeforePicker.selectRow(6, inComponent: 0, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func lifetimeWarrantySwitched(_ sender: Any) {
        tableView.beginUpdates()
        tableView.endUpdates()
//        if lifetimeWarrantySwitch.isOn {
//            for cell in cellsReliantOnEndDate {
//                cell.isHidden = true
//            }
//        } else {
//            for cell in cellsReliantOnEndDate {
//                cell.isHidden = false
//            }
//        }
    }
    
    @IBAction func pickerChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if sender == beginsPicker { // update begins date
            let startDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedStartDate.text = startDate
        } else { // udate end date
            let endDate = dateFormatter.string(from: endsPicker.date)
            self.selectedEndDate.text = endDate
        }

        if endsPicker.date.compare(dateFormatter.date(from: selectedStartDate.text!)!) == .orderedAscending {
            endsPicker.date = beginsPicker.date
            let endDate = dateFormatter.string(from: endsPicker.date)
            self.selectedEndDate.text = endDate
        }
    }
    
    //MARK: Picker View Data Sources and Delegates
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext)!
        
        let record = NSManagedObject(entity: recordEntity, insertInto: managedContext) as! Record
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let startDate = dateFormatter.date(from: selectedStartDate.text!)
        let endDate = dateFormatter.date(from: selectedEndDate.text!)
        let daysBeforeReminder = Int(daysBeforePicker.selectedRow(inComponent: 0)+1)
        
        record.title = titleString
        record.descriptionString = descriptionString
        record.warrantyStarts = startDate
        if lifetimeWarrantySwitch.isOn {
            record.warrantyEnds = NSDate.distantFuture as NSDate as Date as Date
        } else {
            record.warrantyEnds = endDate
        }
        //record.itemImage = itemImageData as NSData?
        //record.receiptImage = receiptImageData as NSData?
        record.daysBeforeReminder = Int32(daysBeforeReminder)
        record.hasWarranty = lifetimeWarrantySwitch.isOn
        record.dateCreated = Date()
        record.lastUpdated = Date()
        record.recentlyDeleted = false
        record.expired = false
        record.recordID = UUID().uuidString
        
        // to find and use the calendar for events:
        if !lifetimeWarrantySwitch.isOn {
            // make sure we have permission for the calendar
            if EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                let calendar = checkCalendar()
                let newEvent = EKEvent(eventStore: eventStore)
                newEvent.calendar = calendar
                newEvent.title = titleString + " Warranty Expires"
                newEvent.notes = "Is your item still working properly?  Its warranty expires today."
                newEvent.startDate = endDate!
                newEvent.endDate = endDate!
                newEvent.isAllDay = true
                // configure alarm for event
                let daysToSubtract = -(daysBeforeReminder+1)
                
                var addingPeriod = DateComponents()
                addingPeriod.day = daysToSubtract
                addingPeriod.hour = 12
                
                let userCalendar = NSCalendar.current
                let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate!) // this is really subtracting...
                
                let alarm = EKAlarm(absoluteDate: alarmDate!)
                newEvent.addAlarm(alarm)
                
                // try to save the event
                do {
                    try eventStore.save(newEvent, span: .thisEvent, commit: true)
                    record.eventIdentifier = newEvent.eventIdentifier
                    print("Event Identifier: " + newEvent.eventIdentifier)
                    self.dismiss(animated: true, completion: nil)
                } catch {
                    let alert = UIAlertController(title: "Event could not be saved", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                record.eventIdentifier = "NotAuthorized"
            }
        } else {
            record.eventIdentifier = "LifetimeWarranty"
        }
        
        let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: managedContext)!
        
        for item in itemImageData {
            let image = NSManagedObject(entity: imageEntity, insertInto: managedContext) as! Image
            
            image.id = UUID().uuidString
            image.record = record
            image.lastSynced = Date()
            image.image = item!
        }
        
        
        // Save the created Record object
        do {
            try managedContext.save()
            // check if the user is signed in, if not then there is nothing to refresh.
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
            if UserDefaultsHelper.syncEnabled() {
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.importCDRecord(cdRecord: record, context: managedContext)
                } else {
                    // queue up the record to sync when you have a good connection
                    UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                }
            }
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    func checkCalendar() -> EKCalendar {
        var retCal: EKCalendar?
        
        let calendars = eventStore.calendars(for: EKEntityType.event) // Grab every calendar the user has
        var exists: Bool = false
        for calendar in calendars { // Search all these calendars
            if calendar.title == "UnderWarranty" {
                exists = true
                retCal = calendar
            }
        }
        
        if !exists {
            let newCalendar = EKCalendar(for:EKEntityType.event, eventStore:eventStore)
            newCalendar.title="UnderWarranty"
            newCalendar.source = eventStore.defaultCalendarForNewEvents?.source
            do {
                try eventStore.saveCalendar(newCalendar, commit:true)
            } catch {
                print("Couldn't add calendar")
            }
            retCal = newCalendar
        }
        
        return retCal!
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                UserDefaultsHelper.setCalendarPermissions(to: true)
                DispatchQueue.main.async(execute: {
                    self.loadCalendars()
                })
            } else {
                UserDefaultsHelper.setCalendarPermissions(to: false)
                DispatchQueue.main.async(execute: {
                    let alertController = UIAlertController(title: "You Sure?", message: "UnderWarranty uses an app specific calendar to alert you when an item is about to leave warranty.  If you change your mind, enable the Calendar switch in Settings.", preferredStyle: UIAlertControllerStyle.alert)
                    
                    // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                        (result : UIAlertAction) -> Void in
                        print("OK")
                    }
                    
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        })
    }
    
    func loadCalendars() {
        calendars = eventStore.calendars(for: EKEntityType.event)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 || indexPath.row == 3 {
            if indexPath.row == 0 {
                beginsCellIsShowing = !beginsCellIsShowing
            } else {
                endsCellIsShowing = !endsCellIsShowing
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if lifetimeWarrantySwitch.isOn {
            if indexPath.row == 1 {
                if beginsCellIsShowing {
                    return 0
                } else {
                    return 140
                }
            }
            
            if indexPath.row > 2 {
                return 0
            } else {
                return originalCellHeights[indexPath.row]
            }
        } else {
            
            if indexPath.row == 1 {
                if beginsCellIsShowing {
                    return 0
                } else {
                    return 140
                }
            } else if indexPath.row == 4 {
                if endsCellIsShowing {
                    return 0
                } else {
                    return 140
                }
            }
            
            return originalCellHeights[indexPath.row]
        }
    }
}

