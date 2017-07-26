//
//  DetailsViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-24.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class DetailsViewController: UIViewController, UIViewControllerPreviewingDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {

    // variables passed from last view
    var record: Record!
    //
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var weeksBeforeLabel: UILabel!
    @IBOutlet weak var weeksBeforeLabel2: UILabel!
    @IBOutlet weak var alertDateLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var weeksBeforeSegment: UISegmentedControl!
    @IBOutlet weak var periodLabel: UILabel!
    
    var originalDescriptionViewCenter = CGPoint(x: 0, y: 0)
    var originalWeeksBeforeEndDateCenter = CGPoint(x: 0, y: 0)
    
    var isEditingRecord = false
    var tappedItem = false
    var tappedReceipt = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemImageView.contentMode = .scaleAspectFit
        receiptImageView.contentMode = .scaleAspectFit
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: record.itemImage as! Data)
        receiptImageView.image = UIImage(data: record.receiptImage as! Data)
        startDateLabel.text = dateFormatter.string(from: record.warrantyStarts as! Date)
        endDateLabel.text = dateFormatter.string(from: record.warrantyEnds as! Date)
        descriptionView.text = record.descriptionString
        descriptionView.textAlignment = .center
        descriptionView.delegate = self
        weeksBeforeLabel.text = String(record.daysBeforeReminder) + " weeks before end date"
        weeksBeforeLabel2.text = weeksBeforeLabel.text
        weeksBeforeSegment.selectedSegmentIndex = record.daysBeforeReminder-1
        weeksBeforeSegment.alpha = 0
        weeksBeforeLabel2.alpha = 0
        
        // configure alarm for event
        let daysToSubtract = Int(record.daysBeforeReminder)*(-7)
        
        var addingPeriod = DateComponents()
        addingPeriod.day = daysToSubtract
        addingPeriod.hour = 12
        
        let userCalendar = NSCalendar.current
        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: record.warrantyEnds as! Date) // this is really subtracting...
        alertDateLabel.text = dateFormatter.string(from: alarmDate!)
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        
        originalDescriptionViewCenter = descriptionView.center
        originalWeeksBeforeEndDateCenter = weeksBeforeLabel.center
        
        // set up tap recognizers
        let startDateTap = UITapGestureRecognizer(target: self, action: #selector(startDateTapped(sender:)))
        let endDateTap = UITapGestureRecognizer(target: self, action: #selector(endDateTapped(sender:)))
        let itemViewTap = UITapGestureRecognizer(target: self, action: #selector(itemViewTapped(sender:)))
        let receiptViewTap = UITapGestureRecognizer(target: self, action: #selector(receiptViewTapped(sender:)))
        startDateLabel.addGestureRecognizer(startDateTap)
        endDateLabel.addGestureRecognizer(endDateTap)
        itemImageView.isUserInteractionEnabled = true
        receiptImageView.isUserInteractionEnabled = true
        itemImageView.addGestureRecognizer(itemViewTap)
        receiptImageView.addGestureRecognizer(receiptViewTap)
        
        deleteButton.title = "Save"
        
        let calendar = NSCalendar.current
        // Replace the hour (time) of both dates with 00:00
        let currentDate = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: record.warrantyEnds as! Date)
        let daysLeft = calendar.dateComponents([.day], from: currentDate, to: endDate)
        
        periodLabel.text = "Warranty: (" + String(daysLeft.day!) + " days left)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    @IBAction func selectedSegmentChanged(_ sender: Any) {
        weeksBeforeLabel2.text = String(weeksBeforeSegment.selectedSegmentIndex+1) + " weeks before end date"
        weeksBeforeLabel.text = weeksBeforeLabel2.text
    }
    
    func startDateTapped(sender: UITapGestureRecognizer) {
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker")  as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = startDateLabel
        popController.popoverPresentationController?.sourceRect = CGRect(x: self.startDateLabel.bounds.midX, y: self.startDateLabel.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: startDateLabel.text!)
        popController.tappedStartDate = true
        
        // present the popover
        //popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func endDateTapped(sender: UITapGestureRecognizer) {
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker") as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = endDateLabel
        popController.popoverPresentationController?.sourceRect = CGRect(x: self.endDateLabel.bounds.midX, y: self.endDateLabel.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: endDateLabel.text!)
        popController.tappedStartDate = false
        
        navBar.title = record.title!
        itemImageView.image = UIImage(data: record.itemImage as! Data)
        
        // present the popover
        //popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func itemViewTapped(sender: UITapGestureRecognizer) {
        // show controller to take photo
        if isEditingRecord {
            tappedItem = true
            tappedReceipt = false
            performSegue(withIdentifier: "editImage", sender: self)
        }
    }
    
    func receiptViewTapped(sender: UITapGestureRecognizer) {
        // show controller to take photo
        if isEditingRecord {
            tappedReceipt = true
            tappedItem = false
            performSegue(withIdentifier: "editImage", sender: self)
        }
    }
    
    func savePreferences (labelText:String, changeStartDate:Bool) {
        if changeStartDate {
            startDateLabel.text = labelText
        } else {
            endDateLabel.text = labelText
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        if isEditingRecord {
            deleteButton.title = "Save"
            deleteButton.tintColor = startDateLabel.tintColor
            startDateLabel.isUserInteractionEnabled = false
            endDateLabel.isUserInteractionEnabled = false
            editButton.title = "Edit"
            isEditingRecord = false
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            
            stopJiggling(viewToStop: itemImageView)
            stopJiggling(viewToStop: receiptImageView)
            
            weeksBeforeLabel.text = weeksBeforeLabel2.text
            
            self.descriptionView.textColor = UIColor.black
            self.descriptionView.isUserInteractionEnabled = false
            self.startDateLabel.textColor = UIColor.black
            self.endDateLabel.textColor = UIColor.black
            
            UIView.animate(withDuration: 0.3, animations: {
                self.alertDateLabel.alpha = 1.0
                self.weeksBeforeLabel.alpha = 1.0
                self.weeksBeforeSegment.alpha = 0
                self.weeksBeforeLabel2.alpha = 0
            }, completion: { finished in
                UIView.animate(withDuration: 0.3, animations: {
                    self.weeksBeforeLabel.center = CGPoint(x: self.weeksBeforeLabel.center.x, y: self.alertDateLabel.center.y)
                })
            })
            
            weeksBeforeLabel.text = weeksBeforeLabel2.text
            
            // reset bools for tapped image views
            tappedReceipt = false
            tappedItem = false
        } else {
            startDateLabel.isUserInteractionEnabled = true
            endDateLabel.isUserInteractionEnabled = true
            editButton.title = "Done"
            isEditingRecord = true
            navBar.setHidesBackButton(isEditingRecord, animated: true)
            deleteButton.title = "Delete"
            deleteButton.tintColor = UIColor.red
            
            startJiggling(viewToShake: itemImageView)
            startJiggling(viewToShake: receiptImageView)
            
            self.descriptionView.textColor = self.descriptionView.tintColor
            self.descriptionView.isUserInteractionEnabled = true
            self.startDateLabel.textColor = self.startDateLabel.tintColor
            self.endDateLabel.textColor = self.endDateLabel.tintColor
            
            UIView.animate(withDuration: 0.5, animations: {
                self.alertDateLabel.alpha = 0
                self.weeksBeforeLabel.alpha = 0
            }, completion: { finished in
                UIView.animate(withDuration: 0.5, animations: {
                    self.weeksBeforeSegment.alpha = 1.0
                    self.weeksBeforeLabel2.alpha = 1.0
                })
            })
            
            weeksBeforeLabel.text = weeksBeforeLabel2.text
        }
    }
    
    func startJiggling(viewToShake: UIImageView) {
        let randomInt: Double = Double(arc4random_uniform(50))
        let r: Double = (randomInt/500.0)+0.5
        
        let leftWobble = CGAffineTransform(rotationAngle: CGFloat(degreesToRadians(x: (1.0 * -1.0) - r )))
        let rightWobble = CGAffineTransform(rotationAngle: CGFloat(degreesToRadians(x: 1.0 + r )))
        
        viewToShake.transform = leftWobble
        
        viewToShake.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [UIViewAnimationOptions.allowUserInteraction, UIViewAnimationOptions.repeat, UIViewAnimationOptions.autoreverse], animations: {
            viewToShake.animationRepeatCount = NSNotFound
            viewToShake.transform = rightWobble
        }, completion: nil)
    }
    
    func stopJiggling(viewToStop: UIView) {
        viewToStop.layer.removeAllAnimations()
        viewToStop.transform = CGAffineTransform.identity
    }
    
    func degreesToRadians(x: Double) -> Double {
        return (M_PI * x)/180.0
    }
    
    // delete button / save button depending on context.
    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        fetchRequest.predicate = NSPredicate(format: "dateCreated==%@", record.dateCreated!)
        let object = try! managedContext.fetch(fetchRequest)
        
        if deleteButton.title == "Delete" { // delete first returned object
            let record = object[0] as! Record
            
            record.recentlyDeleted = true
            record.dateDeleted = Date() as NSDate?
            do {
                try managedContext.save()
            } catch {
                print("The record couldn't be updated.")
            }
        } else { // save or update the returned object
            let record = object[0] as! Record
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            
            record.warrantyStarts = dateFormatter.date(from: startDateLabel.text!) as NSDate?
            record.warrantyEnds = dateFormatter.date(from: endDateLabel.text!) as NSDate?
            record.descriptionString = descriptionView.text!
            record.daysBeforeReminder = weeksBeforeSegment.selectedSegmentIndex+1
            record.itemImage = UIImageJPEGRepresentation(itemImageView.image!, 1.0) as NSData?
            record.receiptImage = UIImageJPEGRepresentation(receiptImageView.image!, 1.0) as NSData?
            
            do {
                try managedContext.save()

                let eventStore = EKEventStore()
                let calendars = eventStore.calendars(for: .event)
                
                for calendar in calendars {
                    if calendar.title == "WarrantyTracker" {
                        let event = eventStore.event(withIdentifier: record.eventIdentifier!)

                        event?.startDate = dateFormatter.date(from: endDateLabel.text!)!
                        let endDate = dateFormatter.date(from: endDateLabel.text!)!
                        event?.endDate = endDate
                        event?.isAllDay = true
                        
                        // remove old alarm and configure new alarm for event
                        if (event?.hasAlarms)! {
                            event?.alarms?.removeAll()
                        }
                        
                        let daysToSubtract = (weeksBeforeSegment.selectedSegmentIndex+1)*(-7)
                        
                        var addingPeriod = DateComponents()
                        addingPeriod.day = daysToSubtract
                        addingPeriod.hour = 12
                        
                        let userCalendar = NSCalendar.current
                        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate) // this is really subtracting...
                        
                        let alarm = EKAlarm(absoluteDate: alarmDate!)
                        event?.addAlarm(alarm)
                        
                        do {
                            try eventStore.save(event!, span: .thisEvent, commit: true)
                        } catch {
                            print("The event couldnt be updated")
                        }
                    }
                }
            } catch {
                print("The record couldn't be saved.")
            }
        }
        
        self.navigationController!.popToRootViewController(animated: true)
    }
    
    // resign first responder on text view return
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            descriptionView.resignFirstResponder()
            return false
        }
        return true
    }
    
    @IBAction func unwindToEdit(with segue: UIStoryboardSegue) {}
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        print("Recognized force touch")
        
        guard let imageViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "ImageViewController") as?
            ImageViewController else {
                return nil
        }
        
        var selectedImageView: UIImageView!
        if itemImageView.frame.contains(location) {
            selectedImageView = itemImageView
        } else if receiptImageView.frame.contains(location) {
            selectedImageView = receiptImageView
        } else {
            return nil
        }
       
        imageViewController.image = selectedImageView.image!
        
        imageViewController.preferredContentSize =
            CGSize(width: 0.0, height: 600)
        
        previewingContext.sourceRect = selectedImageView.frame
        
        return imageViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
            self.setRecentlyDeletedTrue(for: self.record)
        })
        
        let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [delete, cancel]
    }
    
    func setRecentlyDeletedTrue(for record: Record) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        var returnedRecords: [NSManagedObject] = []
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                let thisRecord = thisRecord as! Record
                thisRecord.recentlyDeleted = true
                do {
                    try managedContext.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editImage" {
            if let nextViewController = segue.destination as? EditPhotoViewController {
                if tappedItem {
                    nextViewController.navBar.title = "Item"
                } else if tappedReceipt {
                    nextViewController.navBar.title = "Receipt"
                }
            }
        }
    }
}
