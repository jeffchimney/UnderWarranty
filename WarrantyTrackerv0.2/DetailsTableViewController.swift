//
//  DetailsTableViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-01-10.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit
import EventKit

public protocol DataBackDelegate: class {
    func savePreferences (labelText:String, changeStartDate:Bool)
}
public protocol AddNotesCellDelegate: class {
    func addNotesButtonPressed()
}
public protocol EditImageDelegate: class {
    func removeImage(at indexToDelete:Int)
    func addNewImage(newImage: UIImage, newID: String)
}
public protocol HandleNotesDelegate: class {
    func passBack(newNote: Note, selectedIndex: Int)
    func deleteNote(at index: Int)
}

class DetailsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UIViewControllerPreviewingDelegate, iCarouselDelegate, iCarouselDataSource, DataBackDelegate, AddNotesCellDelegate, EditImageDelegate, HandleNotesDelegate {
    
    // variables passed from last view
    var record: Record!
    //

    var notes: [Note] = []
    var noteIDs: [String] = []
    var images: [UIImage] = []
    var imageIDs: [String] = []
    var imageCarousel: iCarousel!
    
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var keyboardHeight: CGFloat = 0
    var isEditingRecord = false
    var willEditNote = false
    var selectedNotesIndex = -1
    var tappedItem = false
    var tappedReceipt = false
    var originalCellSize = 0
    let generator = UIImpactFeedbackGenerator(style: .medium)
    var changesMade = false
    
    var managedContext: NSManagedObjectContext?
    
    weak var reloadDelegate: ReloadTableViewDelegate?
    
    override func viewDidLoad() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        navBar.title = record.title!
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //images.append(UIImage(data: record.itemImage! as Data)!)
        //images.append(UIImage(data: record.receiptImage! as Data)!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        loadAssociatedNotes()
        loadAssociatedImages()
    
        tableView.reloadData()
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        deleteButton.isEnabled = false
        
//        let defaultBarButtonFont = UIFont(name: "Kohinoor Bangla", size: 17)!
//        let barButtonAttributes = [
//            NSFontAttributeName: defaultBarButtonFont
//        ]
//
//        deleteButton.setTitleTextAttributes(barButtonAttributes, for: .normal)
//        editButton.setTitleTextAttributes(barButtonAttributes, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isEditingRecord {
            if images.count != 0 {
                for index in 0...images.count-1 {
                    startJiggling(viewToShake: imageCarousel!.itemView(at: index) as! UIImageView)
                }
            }
            deleteButton.isEnabled = true
        }
        selectedNotesIndex = -1
    }
    
    func startJiggling(viewToShake: UIImageView) {
        let randomInt: Double = Double(arc4random_uniform(50))
        let r: Double = (randomInt/2000.0)+0.5
        
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
        return (.pi * x)/180.0
    }
    
    func loadAssociatedImages() {
        while images.count > 0 {
            images.removeLast()
        }
        
        let imagesToAppend = CoreDataHelper.fetchImages(for: record, in: managedContext!)
        
        for image in imagesToAppend {
            if image.record?.recordID == record!.recordID {
                images.append(UIImage(data: image.image! as Data)!)
                imageIDs.append(image.id!)
            }
        }
    }
    
    func loadAssociatedNotes() {
        notes = CoreDataHelper.fetchNotes(for: record, in: managedContext!)
        
        for note in notes {
            noteIDs.append(note.id!)
        }
    }
    
    func passBack(newNote: Note, selectedIndex: Int) {
        
        if selectedIndex != 0 {
            if !notes.contains(newNote) {
                notes.append(newNote)
                noteIDs.append(newNote.id!)
                tableView.insertRows(at: [IndexPath(row: notes.count, section: 2)], with: .fade)
            }
        }
    }
    
    func deleteNote(at index: Int) {
        // from core data
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Note")
        fetchRequest.predicate = NSPredicate(format: "id==%@", noteIDs[index-1]) // account for item and receipt images
        let object = try! managedContext.fetch(fetchRequest)
        
        let record = object[0] as! Note
        
        do {
            managedContext.delete(record)
            try managedContext.save()
            // CloudKitHelper.deleteWithID(recordID: noteIDs[index-1])
        } catch {
            print("The record couldn't be deleted.")
        }
        
        notes.remove(at: index-1)
        noteIDs.remove(at: index-1)
        tableView.deleteRows(at: [IndexPath(row: index, section: 2)], with: .fade)
    }
    
    // DURING EDITING /////////////////////////////////////////////////////////////////////////
    
    @IBAction func editButtonPressed(_ sender: Any) {
        //let imageCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
        let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
        let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
        
        if isEditingRecord {
            if changesMade { // save any changes that were made while editing.
                guard let appDelegate =
                    UIApplication.shared.delegate as? AppDelegate else {
                        return
                }
                let managedContext =
                    appDelegate.persistentContainer.viewContext
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                
                let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
                let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
                let descriptionCell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as! NotesTableViewCell
                
                record.warrantyStarts = dateFormatter.date(from: startDateCell.detail.text!)
                if !record.hasWarranty {
                    record.warrantyEnds = dateFormatter.date(from: endDateCell.detail.text!)
                }
                record.descriptionString = descriptionCell.title.text
                record.lastUpdated = Date() as NSDate as Date
                
                do {
                    try managedContext.save()
                    
                    let eventStore = EKEventStore()
                    let calendars = eventStore.calendars(for: .event)
                    
                    if !record.hasWarranty {
                        if EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                            for calendar in calendars {
                                if calendar.title == "UnderWarranty" {
                                    let event = eventStore.event(withIdentifier: record.eventIdentifier!)
                                    
                                    event?.startDate = dateFormatter.date(from: endDateCell.detail.text!)!
                                    let endDate = dateFormatter.date(from: endDateCell.detail.text!)!
                                    event?.endDate = endDate
                                    event?.isAllDay = true
                                    
                                    // remove old alarm and configure new alarm for event
                                    if (event?.hasAlarms)! {
                                        event?.alarms?.removeAll()
                                    }
                                    
                                    let daysToSubtract = Int(-record.daysBeforeReminder)
                                    
                                    var addingPeriod = DateComponents()
                                    addingPeriod.day = daysToSubtract
                                    addingPeriod.hour = 12
                                    
                                    let userCalendar = NSCalendar.current
                                    let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate) // this is really subtracting...
                                    
                                    let alarm = EKAlarm(absoluteDate: alarmDate!)
                                    event?.addAlarm(alarm)
                                    
                                    do {
                                        try eventStore.save(event!, span: .thisEvent, commit: true)
                                        self.navigationController!.popToRootViewController(animated: true)
                                    } catch {
                                        print("The event couldnt be updated")
                                    }
                                }
                            }
                        }
                    }
                    
                    // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
//                    let conn = UserDefaultsHelper.currentConnection()
//                    if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
//                        CloudKitHelper.updateRecordInCloudKit(cdRecord: record, context: managedContext)
//                    } else {
//                        // queue up the record to sync when you have a good connection
//                        UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
//                    }
                    navigationController?.popViewController(animated: true)
                } catch {
                    print("The record couldn't be saved.")
                }
            }
            
            //deleteButton.title = "Save"
            //deleteButton.tintColor = tableView.tintColor
            deleteButton.isEnabled = false
            startDateCell.isUserInteractionEnabled = false
            endDateCell.isUserInteractionEnabled = false
            editButton.title = "Edit"
            isEditingRecord = false
            //navBar.setHidesBackButton(isEditingRecord, animated: true)
            
            startDateCell.detail.textColor = UIColor.black
            endDateCell.detail.textColor = UIColor.black
            
            // reset bools for tapped image views
            tappedReceipt = false
            tappedItem = false
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: notes.count + 1, section: 2)], with: UITableViewRowAnimation.fade)
            tableView.endUpdates()
            
            imageCarousel.reloadData()
        } else {
            deleteButton.isEnabled = true
            startDateCell.isUserInteractionEnabled = true
            if !record.hasWarranty {
                endDateCell.isUserInteractionEnabled = true
                endDateCell.detail.textColor = tableView.tintColor
            } else {
                endDateCell.isUserInteractionEnabled = false
            }
            editButton.title = "Done"
            isEditingRecord = true
            //navBar.setHidesBackButton(isEditingRecord, animated: true)
            //deleteButton.title = "Delete"
            //deleteButton.tintColor = UIColor.red
            
            if images.count > 0 {
                for index in 0...images.count-1 {
                    if imageCarousel!.numberOfItems > 0 {
                        startJiggling(viewToShake: imageCarousel!.itemView(at: index) as! UIImageView)
                    }
                }
            }
            
            startDateCell.detail.textColor = tableView.tintColor
            
            tableView.beginUpdates()
            tableView.insertRows(at: [IndexPath(row: notes.count + 1, section: 2)], with: UITableViewRowAnimation.fade)
            tableView.endUpdates()
            
            imageCarousel.insertItem(at: images.count, animated: true)
        }
    }
    
    func startDateTapped() {
        generator.impactOccurred()
        let startDateCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker")  as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = [UIPopoverArrowDirection.down, UIPopoverArrowDirection.up]
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = startDateCell.detail
        popController.popoverPresentationController?.sourceRect = CGRect(x: startDateCell.detail.bounds.midX, y: startDateCell.detail.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: startDateCell.detail.text!)
        popController.tappedStartDate = true
        
        // present the popover
        popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func endDateTapped() {
        generator.impactOccurred()
        let endDateCell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
        // set up the popover presentation controller
        let popController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DatePicker") as! EditDateController
        popController.modalPresentationStyle = UIModalPresentationStyle.popover
        popController.popoverPresentationController?.permittedArrowDirections = [UIPopoverArrowDirection.down, UIPopoverArrowDirection.up]
        popController.popoverPresentationController?.delegate = self
        popController.popoverPresentationController?.sourceView = endDateCell.detail
        popController.popoverPresentationController?.sourceRect = CGRect(x: endDateCell.detail.bounds.midX, y: endDateCell.detail.bounds.minY, width: 0, height: 0)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        popController.pickedDate = dateFormatter.date(from: endDateCell.detail.text!)
        popController.tappedStartDate = false
        
        // present the popover
        popController.delegate = self
        self.present(popController, animated: true, completion: nil)
    }
    
    func itemViewTapped(sender: UITapGestureRecognizer) {
        generator.impactOccurred()
        performSegue(withIdentifier: "toImageView", sender: self)
    }
    
    func receiptViewTapped(sender: UITapGestureRecognizer) {
        generator.impactOccurred()
        performSegue(withIdentifier: "toImageView", sender: self)
    }
    
    @objc func imageViewTapped(sender: UITapGestureRecognizer) {
        generator.impactOccurred()
        performSegue(withIdentifier: "toImageView", sender: self)
    }
    
    @objc func addButtonTapped(sender: Any) {
        generator.impactOccurred()
        tappedItem = false
        tappedReceipt = false
        performSegue(withIdentifier: "editImage", sender: self)
    }
    
    func addNotesButtonPressed() {
        performSegue(withIdentifier: "toCreateNote", sender: self)
    }
    
    func removeImage(index: Int) {
        DispatchQueue.main.async() {
            self.removeImage(at: index)
            self.images.remove(at: index)
        }
    }
    
    func addNewImage(newImage: UIImage, newID: String) {
        self.images.append(newImage)
        imageIDs.append(newID)
        imageCarousel.insertItem(at: images.count - 1, animated: true)
    }
    
    func removeImage(at indexToDelete: Int) {
        // from core data
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Image")
        fetchRequest.predicate = NSPredicate(format: "id==%@", imageIDs[indexToDelete]) // account for item and receipt images
        let object = try! managedContext.fetch(fetchRequest)

        let record = object[0] as! Image
        
        do {
            managedContext.delete(record)
            try managedContext.save()
            //CloudKitHelper.deleteWithID(recordID: imageIDs[indexToDelete])
        } catch {
            print("The record couldn't be deleted.")
        }
        
        imageCarousel.removeItem(at: indexToDelete, animated: true)
        images.remove(at: indexToDelete)
        imageIDs.remove(at: indexToDelete)
    }
    
    @objc func keyboardWillShow(notification:NSNotification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        keyboardHeight = keyboardRectangle.height
    }
    
    func addBottomBorder(to view: UIView) {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = UIColor.lightGray.cgColor
        border.frame = CGRect(x: 0, y: view.frame.size.height - width, width:  view.frame.size.width, height: view.frame.size.height)
        
        border.borderWidth = width
        view.layer.addSublayer(border)
        view.layer.masksToBounds = true
    }
    
    func translateDown(view: UIView) {
        tableView.isScrollEnabled = true
        UIView.animate(withDuration: 0.5, animations: {
            view.center = CGPoint(x: self.view.center.x, y: self.view.center.y*3)
        }, completion: { completed in
            view.removeFromSuperview()
            
        })
    }
    
    func savePreferences (labelText:String, changeStartDate:Bool) {
        if changeStartDate {
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! InfoTableViewCell
            cell.detail.text = labelText
        } else {
            let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as! InfoTableViewCell
            cell.detail.text = labelText
        }
        changesMade = true
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return UINavigationController(rootViewController: controller.presentedViewController)
    }
    
    //////////////////////////////////////////////////////////////////////////
    
    override var previewActionItems: [UIPreviewActionItem] {
        
        let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
            self.setRecentlyDeletedTrue(for: self.record)
            self.reloadDelegate?.reloadLastControllerTableView()
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
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        CoreDataHelper.set(recentlyDeleted: true, for: record, in: managedContext)
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        if deleteButton.title == "Delete" { // delete first returned object
            record.recentlyDeleted = true
            record.dateDeleted = Date() as NSDate as Date
            record.lastUpdated = Date() as NSDate as Date
            do {
                try managedContext.save()
                
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
//                let conn = UserDefaultsHelper.currentConnection()
//                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
//                    CloudKitHelper.updateRecordInCloudKit(cdRecord: record, context: managedContext)
//                } else {
//                    // queue up the record to sync when you have a good connection
//                    UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
//                }
                
                navigationController?.popViewController(animated: true)
            } catch {
                print("The record couldn't be updated.")
            }
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let title = "Title: " + record.title! + "\n"
        let descriptionText = "Description: " + record.descriptionString! + "\n"
        let spanOfTime = "Valid from " + dateFormatter.string(from:  record.warrantyStarts! as Date) + " until " + dateFormatter.string(from:  record.warrantyEnds! as Date) + ".\n"
        var activityItems: [Any] = [title, descriptionText, spanOfTime]
        activityItems.append("Notes:")
        for each in notes {
            activityItems.append(each.noteString!)
        }
        for eachImage in images {
            activityItems.append(eachImage)
        }
        
        activityItems.append("\nSent using UnderWarranty.")
        
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
        
        present(vc, animated: true, completion: nil)
    }
    
    
    // MARK: Table View Delegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            if !record.hasWarranty {
                return 4
            } else {
                return 2
            }
        }
        if section == 2 {
            if isEditingRecord {
                return notes.count + 2
            } else {
                return notes.count + 1
            }
        }
        else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Images"
        }
        if section == 1 {
            return "Info"
        }
        if section == 2 {
            return "Notes"
        }
        else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            if indexPath.section == 2 {
                self.selectedNotesIndex = indexPath.row
                self.performSegue(withIdentifier: "toCreateNote", sender: nil)
            }
        }
        edit.backgroundColor = tableView.tintColor
        
        // delete record on press delete
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            if indexPath.section == 2 && indexPath.row != 0 { //
                self.deleteNote(at: indexPath.row)
            }
        }
        delete.backgroundColor = .red
        
        if indexPath.section == 2 && indexPath.row == 0 {
            return [edit]
        } else if indexPath.section == 2 && indexPath.row != 0{
            return [delete, edit]
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Images Cell
        if indexPath.section == 0 {
            if imageCarousel == nil {
                imageCarousel = iCarousel(frame: CGRect(x: 0, y: 0, width: 375, height: 240))
                imageCarousel.dataSource = self
                imageCarousel.type = .coverFlow
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "imagesCell", for: indexPath) as! ImagesTableViewCell
            
            cell.cellCarouselView.addSubview(imageCarousel)
            
            return cell
        }
        // Info Cells
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "infoCell", for: indexPath) as! InfoTableViewCell
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            
            if indexPath.row == 0 {
                cell.title.text = "Start Date"
                cell.detail.text = dateFormatter.string(from: record.warrantyStarts! as Date)
            }
            if indexPath.row == 1 {
                cell.title.text = "End Date"
                if !record.hasWarranty {
                    cell.detail.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.detail.text = "∞"
                }
            }
            
            if !record.hasWarranty {
                if indexPath.row == 2 {
                    
                    // calculate alarm for event
                    let daysToSubtract = Int(-record.daysBeforeReminder)
                    
                    var addingPeriod = DateComponents()
                    addingPeriod.day = daysToSubtract
                    addingPeriod.hour = 12
                    
                    let userCalendar = NSCalendar.current
                    let alarmDate = userCalendar.date(byAdding: addingPeriod, to: record.warrantyEnds! as Date) // this is really subtracting...
                    
                    cell.title.text = "Scheduled Alert"
                    cell.detail.text = dateFormatter.string(from: alarmDate!)
                }
                if indexPath.row == 3 {
                    let calendar = NSCalendar.current
                    // Replace the hour (time) of both dates with 00:00
                    let currentDate = calendar.startOfDay(for: Date())
                    let endDate = calendar.startOfDay(for: record.warrantyEnds! as Date)
                    let daysLeft = calendar.dateComponents([.day], from: currentDate, to: endDate)
                    
                    cell.title.text = "Days Remaining"
                    cell.detail.text = String(daysLeft.day!)
                }
            }
            
            return cell
        }
        // Notes cells
        if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath) as! NotesTableViewCell
                
                cell.noteImageView.layer.cornerRadius = 20//cell.noteImageView.frame.width/2
                cell.noteImageView.layer.masksToBounds = false
                cell.noteImageView.clipsToBounds = true
            
                cell.title.text = record.descriptionString
                return cell
            } else if indexPath.row < notes.count+1 {
                print(String(indexPath.row) + " <= " + String(notes.count))
                let cell = tableView.dequeueReusableCell(withIdentifier: "notesCell", for: indexPath) as! NotesTableViewCell
    
                cell.noteImageView.layer.cornerRadius = 20//cell.noteImageView.frame.width/2
                cell.noteImageView.layer.masksToBounds = false
                cell.noteImageView.clipsToBounds = true
                cell.title.text = notes[indexPath.row-1].title
                cell.note = notes[indexPath.row-1]

                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath) as! AddTableViewCell
                cell.addNotesDelegate = self
                return cell
            }
        }
        // shouldnt get called.
        else {
            return UITableViewCell() // shouldn't ever get called
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // INFO ROWS
        if isEditingRecord {
            if indexPath.section == 1 {
                if indexPath.row == 0 { // start date tapped
                    startDateTapped()
                }
                if indexPath.row == 1 { // end date tapped
                    endDateTapped()
                }
                if indexPath.row == 2 {
                
                }
            }
            
            // NOTES
            if indexPath.section == 2 {
                generator.impactOccurred()
                for index in 0...notes.count+1 {
                    if indexPath.row == index && indexPath.row <= notes.count {
                        selectedNotesIndex = indexPath.row
                        willEditNote = true
                        performSegue(withIdentifier: "toCreateNote", sender: nil)
                    }
                }
            }
        } else {
            // NOTES
            if indexPath.section == 2 {
                generator.impactOccurred()
                for index in 0...notes.count+1  {
                    if indexPath.row == index && indexPath.row <= notes.count {
                        selectedNotesIndex = indexPath.row
                        willEditNote = false
                        performSegue(withIdentifier: "toCreateNote", sender: nil)
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section > 0 {
            return .delete
        }
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 240
        } else {
            return 55
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 240
        } else {
            return 55
        }
    }
    
    // MARK: iCarousel Delegates
    func numberOfItems(in carousel: iCarousel) -> Int {
        if (isEditingRecord) {
            return images.count + 1
        } else {
            return images.count
        }
    }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let imageView: UIImageView
        
        if view != nil {
            imageView = UIImageView()//view as! UIImageView
        } else {
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 180, height: 240))
        }
    
        if index < images.count {
            imageView.image = images[index]
            imageView.isUserInteractionEnabled = true
            let imageViewTap = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped(sender:)))
            imageView.addGestureRecognizer(imageViewTap)
            
            imageView.layer.cornerRadius = 10
            imageView.layer.masksToBounds = true
            
            if isEditingRecord {
                startJiggling(viewToShake: imageView)
            }
//            }
        } else {
            let addView = UIView(frame: CGRect(x: 0, y: 0, width: 180, height: 240))
            
            let addButton = UIButton()
            addButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            addButton.layer.cornerRadius = 20
            addButton.setTitle("+", for: .normal)
            addButton.titleLabel?.font = UIFont(name: (addButton.titleLabel?.font.fontName)!, size: 30)
            addButton.backgroundColor = self.tableView.tintColor
            addButton.center = CGPoint(x: addView.frame.width/2, y: addView.frame.height/2)
            addButton.addTarget(self, action: #selector(addButtonTapped(sender:)), for: .touchUpInside)
            addView.addSubview(addButton)
            return addView
        }
    
        return imageView
    }
    
    // MARK: Segues
    @IBAction func unwindToEdit(with segue: UIStoryboardSegue) {
        
        if segue.identifier == "unwindFromCreateNote" {
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editImage" {
            if let nextViewController = segue.destination as? EditPhotoViewController {
                nextViewController.record = record
//                if tappedItem {
//                    nextViewController.navBar.title = "Item"
//                    nextViewController.editImageDelegate = self
//                } else if tappedReceipt {
//                    nextViewController.navBar.title = "Receipt"
//                    nextViewController.editImageDelegate = self
//                } else {
                    // tapped "add" button on carousel or an image that isnt the item or receipt.
                nextViewController.navBar.title = "New Picture"
                nextViewController.record = record
                nextViewController.editImageDelegate = self
                
                let selectedView = imageCarousel.currentItemView
                if imageCarousel.index(ofItemView: selectedView!) == imageCarousel.numberOfItems-1 {
                    print("Tapped plus button")
                    nextViewController.editImageDelegate = self
                } else {
                    print("Tapped image at index " + String(imageCarousel.index(ofItemView: selectedView!)))
                    nextViewController.indexTapped = imageCarousel.index(ofItemView: selectedView!)
                    nextViewController.editImageDelegate = self
                }
                //}
            }
        }
        if segue.identifier == "toCreateNote" {
            if let nextViewController = segue.destination as? NoteViewController {
                let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext!)!
                nextViewController.record = record
                nextViewController.handleNotesDelegate = self
                nextViewController.isEditingRecord = isEditingRecord
                nextViewController.selectedNotesIndex = selectedNotesIndex
                
                if selectedNotesIndex != -1  && selectedNotesIndex != 0{
                    nextViewController.title = "Edit Note"
                    nextViewController.note = notes[selectedNotesIndex-1]
                }
                
                if isEditingRecord && !willEditNote && selectedNotesIndex != 0 { // create new note
                    nextViewController.navBar.title = "Create Note"
                    let emptyNote = NSManagedObject(entity: noteEntity, insertInto: managedContext) as! Note
                    emptyNote.title = "Title"
                    emptyNote.noteString = "Body"
                    emptyNote.record = record
                    emptyNote.id = "temp"
                    nextViewController.note = emptyNote
                }
                
                if selectedNotesIndex == 0 {
                    let descriptionNote = NSManagedObject(entity: noteEntity, insertInto: managedContext) as! Note
                    descriptionNote.title = "Description:"
                    descriptionNote.noteString = record.descriptionString!
                    descriptionNote.id = "descriptionNote"
                    nextViewController.note = descriptionNote
                }
            }
        }
        if segue.identifier == "toImageView" {
            if let nextViewController = segue.destination as? ImageViewController {
                let selectedImageView = imageCarousel.currentItemView as! UIImageView
                nextViewController.image = selectedImageView.image!
                nextViewController.imageIndex = imageCarousel.currentItemIndex
                nextViewController.isEditingRecord = isEditingRecord
                nextViewController.deleteImageDelegate = self
            }
        }
    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = tableView.cellForRow(at: indexPath) else {
                return nil
        }
        
        // handle 3D touch on image carousel
        if indexPath.section == 0 {
            guard let currentView = imageCarousel.currentItemView as? UIImageView else {
                return nil
            }
            guard let imageViewController =
                    storyboard?.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController else {
                return nil
            }
        
            imageViewController.image = currentView.image
            imageViewController.imageIndex = imageCarousel.currentItemIndex
            imageViewController.isEditingRecord = isEditingRecord
            imageViewController.deleteImageDelegate = self
            imageViewController.preferredContentSize =
                CGSize(width: 0.0, height: 500)
        
            previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
            
            return imageViewController
        }
        
        // handle 3d touch on notes
        if indexPath.section == 2 {
            guard let noteViewController =
                storyboard?.instantiateViewController(withIdentifier: "NoteViewController") as? NoteViewController else {
                    return nil
            }
            
            noteViewController.record = record
            noteViewController.handleNotesDelegate = self
            noteViewController.isEditingRecord = isEditingRecord
            noteViewController.selectedNotesIndex = indexPath.row
            
            if indexPath.row == 0 {
                let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: managedContext!)!
                let descriptionNote = NSManagedObject(entity: noteEntity, insertInto: managedContext) as! Note
                descriptionNote.title = "Description:"
                descriptionNote.noteString = record.descriptionString!
                descriptionNote.id = "descriptionNote"
                noteViewController.note = descriptionNote
            } else {
                noteViewController.navBar.title = "Edit Note"
                noteViewController.note = notes[indexPath.row-1]
            }
            
            noteViewController.preferredContentSize =
                CGSize(width: 0.0, height: 500)
            
            previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
            
            return noteViewController
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
