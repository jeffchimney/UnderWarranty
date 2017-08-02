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

class WarrantyBeginsEndsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // variables that have been passed forward
    var titleString: String! = nil
    var descriptionString: String! = nil
    var itemImageData: [Data?] = []
    //var receiptImageData: Data! = nil
    //
    
    @IBOutlet weak var beginsPicker: UIDatePicker!
    @IBOutlet weak var selectedStartDate: UILabel!
    @IBOutlet weak var selectedEndDate: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var saveDateButton: UIButton!
    @IBOutlet weak var warrantyBeginsLabel: UILabel!
    @IBOutlet weak var warrantyEndsLabel: UILabel!
    @IBOutlet weak var navBar: UINavigationItem!
    //@IBOutlet weak var numberOfWeeksSegment: UISegmentedControl!
    @IBOutlet weak var daysBeforePicker: UIPickerView!
    @IBOutlet weak var remindMeLabel1: UILabel!
    @IBOutlet weak var remindMeLabel2: UILabel!
    @IBOutlet weak var datesSlidingView: UIView!
    @IBOutlet weak var daysBeforeSlidingView: UIView!
    @IBOutlet weak var lifetimeWarrantySwitch: UISwitch!
    
    var startDatePicked = false
    var endDatePicked = false
    var hasWarranty = true
    var pickerData: [String] = []
    var navBarHeight: CGFloat!
    
    let defaults = UserDefaults.standard
    let eventStore = EKEventStore()
    var calendars: [EKCalendar]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beginsPicker.datePickerMode = UIDatePickerMode.date
        selectedStartDate.text = ""
        selectedEndDate.text = ""
        
        selectedStartDate.textColor = UIColor.red
        selectedEndDate.textColor = UIColor.red
        saveDateButton.setTitle("Set Start Date", for: .normal)
        saveDateButton.layer.cornerRadius = 10
        warrantyBeginsLabel.isHidden = true
        warrantyEndsLabel.isHidden = true
        selectedEndDate.isHidden = true
        navBar.title = "Warranty"
        saveButton.isEnabled = false
        
        remindMeLabel1.isHidden = true
        daysBeforePicker.isHidden = true
        remindMeLabel2.isHidden = true
        
        for index in 1...31 {
            pickerData.append(String(index))
        }
        
        daysBeforePicker.delegate = self
        
        datesSlidingView.layer.shadowColor = UIColor.black.cgColor
        datesSlidingView.layer.shadowOpacity = 0.7
        datesSlidingView.layer.shadowOffset = CGSize.zero
        datesSlidingView.layer.shadowRadius = 5
        datesSlidingView.translatesAutoresizingMaskIntoConstraints = true
        datesSlidingView.layer.cornerRadius = 15
        
        daysBeforeSlidingView.layer.shadowColor = UIColor.black.cgColor
        daysBeforeSlidingView.layer.shadowOpacity = 0.7
        daysBeforeSlidingView.layer.shadowOffset = CGSize.zero
        daysBeforeSlidingView.layer.shadowRadius = 5
        daysBeforeSlidingView.translatesAutoresizingMaskIntoConstraints = true
        daysBeforeSlidingView.layer.cornerRadius = 15
        lifetimeWarrantySwitch.isHidden = true
        
        navBarHeight = navigationController!.navigationBar.frame.height
        navigationController?.isToolbarHidden = true
        
        if !UserDefaultsHelper.hasCalendarPermissions() {
            requestAccessToCalendar()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        daysBeforePicker.selectRow(6, inComponent: 0, animated: false)
        datesSlidingView.center.y = -datesSlidingView.frame.height
        print(daysBeforeSlidingView.center.y)
        daysBeforeSlidingView.center.y = view.frame.height + daysBeforeSlidingView.frame.height
        print(daysBeforeSlidingView.center.y)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func lifetimeWarrantySwitched(_ sender: Any) {
        if lifetimeWarrantySwitch.isOn {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    @IBAction func pickerChanged(_ sender: Any) {
        if startDatePicked { // make sure end date is never earlier than start date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            print(beginsPicker.date.compare(dateFormatter.date(from: selectedStartDate.text!)!) == .orderedAscending)

            if beginsPicker.date.compare(dateFormatter.date(from: selectedStartDate.text!)!) == .orderedAscending {
                beginsPicker.date = dateFormatter.date(from: selectedStartDate.text!)!
            }
        }
    }
    
    @IBAction func saveDateButtonPressed(_ sender: Any) {
        if startDatePicked == false && endDatePicked == false { // set start date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let startDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedStartDate.text = startDate
            
            selectedStartDate.isHidden = false
            warrantyBeginsLabel.isHidden = false
            saveDateButton.setTitle("Set End Date", for: .normal)
            startDatePicked = true
            saveButton.isEnabled = false
            lifetimeWarrantySwitch.isHidden = false
            lifetimeWarrantySwitch.isOn = false
            warrantyEndsLabel.text = "Lifetime"
            warrantyEndsLabel.isHidden = false
            
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                //let statusHeight = UIApplication.shared.statusBarFrame.size.height
                self.datesSlidingView.center.y = self.datesSlidingView.frame.height/2
            }, completion: { (_) in
            })
            
        } else if startDatePicked == true && endDatePicked == false { // set end date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            let endDate = dateFormatter.string(from: beginsPicker.date)
            self.selectedEndDate.text = endDate
            warrantyEndsLabel.text = "Ends"
            warrantyEndsLabel.alpha = 0
            selectedEndDate.alpha = 0
            lifetimeWarrantySwitch.isHidden = true
            lifetimeWarrantySwitch.isOn = false
            warrantyEndsLabel.isHidden = false
            selectedEndDate.isHidden = false
            saveDateButton.setTitle("Change Dates", for: .normal)
            endDatePicked = true
            saveButton.isEnabled = true
            
            remindMeLabel1.isHidden = false
            daysBeforePicker.isHidden = false
            remindMeLabel2.isHidden = false
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                self.warrantyEndsLabel.alpha = 1
                self.selectedEndDate.alpha = 1
                self.daysBeforeSlidingView.center.y = self.view.frame.height - self.daysBeforeSlidingView.frame.height/2
//            }, completion: { (_) in
//                print(self.daysBeforeSlidingView.center.y)
//                
//                UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
//                    self.daysBeforeSlidingView.center.y = self.view.frame.height - self.daysBeforeSlidingView.frame.height/2
//                }, completion: nil)
//            })
            })
        } else if startDatePicked == true && endDatePicked == true { // clear both dates and start over
            self.selectedStartDate.text = ""
            self.selectedEndDate.text = ""
            warrantyEndsLabel.isHidden = true
            selectedStartDate.isHidden = true
            lifetimeWarrantySwitch.isHidden = true
            selectedEndDate.isHidden = true
            startDatePicked = false
            endDatePicked = false
            saveButton.isEnabled = false
            saveDateButton.setTitle("Set Start Date", for: .normal)
            
            UIView.animate(withDuration: 0.5, delay: 0, options: [], animations: {
                self.warrantyEndsLabel.alpha = 1
                self.selectedEndDate.alpha = 1
                
                self.daysBeforeSlidingView.center.y = self.view.frame.height + self.daysBeforeSlidingView.frame.height/2
                self.datesSlidingView.center.y = -self.datesSlidingView.frame.height/2
            }, completion: { (_) in
                print(self.daysBeforeSlidingView.center.y)
            })
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
        record.warrantyStarts = startDate as NSDate?
        if lifetimeWarrantySwitch.isOn {
            record.warrantyEnds = NSDate.distantFuture as NSDate
        } else {
            record.warrantyEnds = endDate as NSDate?
        }
        //record.itemImage = itemImageData as NSData?
        //record.receiptImage = receiptImageData as NSData?
        record.daysBeforeReminder = Int32(daysBeforeReminder)
        record.hasWarranty = lifetimeWarrantySwitch.isOn
        record.dateCreated = Date() as NSDate?
        record.lastUpdated = Date() as NSDate?
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
            image.lastSynced = Date() as NSDate
            image.image = item! as NSData
        }
        
        
        // Save the created Record object
        do {
            try managedContext.save()
            // check if the user is signed in, if not then there is nothing to refresh.
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
            let conn = UserDefaultsHelper.currentConnection()
            if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                CloudKitHelper.importCDRecord(cdRecord: record, context: managedContext)
            } else {
                // queue up the record to sync when you have a good connection
                UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
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
            newCalendar.source = eventStore.defaultCalendarForNewEvents.source
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
}

