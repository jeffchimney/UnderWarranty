
//
//  SecondViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

public protocol ReloadTableViewDelegate: class {
    func reloadLastControllerTableView()
}

class PrimaryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIViewControllerPreviewingDelegate, UIScrollViewDelegate, ReloadTableViewDelegate {
    
    var managedContext: NSManagedObjectContext?
    let searchController = UISearchController(searchResultsController: nil)
    var searchActive = false
    var rectOfLastRow = CGRect()
    var lastCell: WarrantyTableViewCell!
    var originalSearchViewCenter = CGPoint(x:0, y:0) // both of these are set in view did load
    var originalTableViewCenter = CGPoint(x:0, y:0) //
    var hidingSearchView = false
    var refreshControl: UIRefreshControl!
    
    //var backToTopButton: UIButton!

    //@IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var sortBySegmentControl: UISegmentedControl!
    @IBOutlet weak var warrantiesTableView: UITableView!
    @IBOutlet weak var archiveButton: UIBarButtonItem!
    let cellIdentifier = "WarrantyTableViewCell"
    var records: [Record] = []
    var filteredRecords: [Record] = []
    var ckRecords: [CKRecord] = []
    var cdImagesForRecord: [Image] = []
    var ckImagesForRecord: [CKRecord] = []
    var cdNotesForRecord: [Note] = []
    var ckNotesForRecord: [CKRecord] = []
    var sections: [[Record]] = [[]]
    var selectedRecord: Record!
    let defaults = UserDefaults.standard
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    let container = CKContainer.default()
    var privateDB: CKDatabase!
    let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
    var createdCustomZone = false
    let recordsSubscriptionID = "records-subscription"
    let notesSubscriptionID = "notes-subscription"
    let imagesSubscriptionID = "images-subscription"
    let subscriptionSavedKey = "ckSubscriptionSaved"
    let serverChangeTokenKey = "ckServerChangeToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set up zone.
        if defaults.object(forKey: "zoneCreated") == nil || defaults.bool(forKey: "zoneCreated") == false {
            createCustomZoneAndSetupSubscriptions()
        }
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext

        self.warrantiesTableView.delegate = self
        self.warrantiesTableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        warrantiesTableView.addSubview(refreshControl)
        
        // sorted by recent by default
        sortBySegmentControl.selectedSegmentIndex = 0
        
        self.warrantiesTableView.reloadData()
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .default
        searchController.searchBar.backgroundColor = warrantiesTableView.tintColor
        definesPresentationContext = true
        
        searchController.searchBar.delegate = self
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        warrantiesTableView.tableHeaderView = searchController.searchBar
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusManager), name: .flagsChanged, object: Network.reachability)
        
        // fonts
        let defaultFont = UIFont(name: "Kohinoor Bangla", size: 15)!
        let attributes = [
            NSFontAttributeName: defaultFont
        ]
        let defaultBarButtonFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        let barButtonAttributes = [
            NSFontAttributeName: defaultBarButtonFont
        ]
        
        sortBySegmentControl.setTitleTextAttributes(attributes, for: .normal)
        searchButton.setTitleTextAttributes(barButtonAttributes, for: .normal)
        
         let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as! UITextField
        textFieldInsideSearchBar.defaultTextAttributes = attributes
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont(name: "Kohinoor Telugu", size: 18)!]
        
        updateUserInterface()
        handleRefresh(refreshControl: refreshControl)
    }
    
    func createCustomZoneAndSetupSubscriptions() {
        let createZoneGroup = DispatchGroup()
        privateDB = container.privateCloudDatabase
        
        if !self.createdCustomZone {
            createZoneGroup.enter()
            
            let customZone = CKRecordZone(zoneID: zoneID)
            
            let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
            
            createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                if (error == nil) { self.createdCustomZone = true }
                // else custom error handling
                createZoneGroup.leave()
            }
            createZoneOperation.qualityOfService = .userInitiated
            
            privateDB.add(createZoneOperation)
            
            UserDefaults.standard.set(true, forKey: "zoneCreated")
            
            saveSubscription()
        }
    }
    
    public func saveSubscription() {
        // Use a local flag to avoid saving the subscription more than once.
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionSavedKey)
        guard !alreadySaved else {
            return
        }
        
        let createRecordsSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: recordsSubscriptionID, recordType: "Records")
        createRecordsSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
            if error != nil {
                // else custom error handling
                print("Failed to add record subscription")
            }
        }
        let createImagesSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: imagesSubscriptionID, recordType: "Images")
        createImagesSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
            if error != nil {
                // else custom error handling
                print("Failed to add images subscription")
            }
        }
        let createNotesSubscriptionOperation = self.createDatabaseSubscriptionOperation(subscriptionId: notesSubscriptionID, recordType: "Notes")
        createNotesSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
            if error != nil {
                // else custom error handling
                print("Failed to add notes subscription")
            }
        }
        self.privateDB.add(createRecordsSubscriptionOperation)
        self.privateDB.add(createImagesSubscriptionOperation)
        self.privateDB.add(createNotesSubscriptionOperation)
        
        UserDefaults.standard.set(true, forKey: self.subscriptionSavedKey)
    }
    
    func createDatabaseSubscriptionOperation(subscriptionId: String, recordType: String) -> CKModifySubscriptionsOperation {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionId, options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        //let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
        
        let notificationInfo = CKNotificationInfo()
        // send a silent notification
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        
        return operation
    }
    
    public static func handleRecordNotification(notification: CKNotification) {
        // Use the ChangeToken to fetch only whatever changes have occurred since the last
        // time we asked, since intermediate push notifications might have been dropped.
        let serverChangeTokenKey = "ckServerChangeToken"
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        var changeToken: CKServerChangeToken? = nil
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        if changeTokenData != nil {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
        }
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken
        let optionsMap = [zoneID: options]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionsMap)
        operation.fetchAllChanges = true
        operation.recordChangedBlock = { record in
            if record.recordType == "Records" {
                let queryNotification = notification as! CKQueryNotification
                DispatchQueue.main.async {
                    print(record)
                    print(record.value(forKey: "title"))
                    print(record.value(forKey: "descriptionString"))
                    print(record.value(forKey: "daysBeforeReminder"))
                    print(record.value(forKey: "eventIdentifier"))
                    print(record.value(forKey: "expired"))
                    print(record.value(forKey: "hasWarranty"))
                    print(record.value(forKey: "recentlyDeleted"))
                    print(record.value(forKey: "warrantyStarts"))
                    print(record.value(forKey: "warrantyEnds"))
                    print(queryNotification.queryNotificationReason == .recordDeleted)
                }
                
                if queryNotification.queryNotificationReason == .recordUpdated {
                    CoreDataHelper.cloudKitRecordChanged(record: record, in: managedContext)//, reload: self.warrantiesTableView)
                } else if queryNotification.queryNotificationReason == .recordCreated {
                    CoreDataHelper.cloudKitRecordCreated(record: record, in: managedContext)
                }
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            if recordType == "Records" {
                let queryNotification = notification as! CKQueryNotification
                if queryNotification.queryNotificationReason == .recordDeleted {
                    // try to find the record in coredata
                    let fetchedRecord = CoreDataHelper.fetchRecord(with: deletedRecordID.recordName, in: managedContext)
                    
                    if fetchedRecord != nil {
                        CoreDataHelper.delete(record: fetchedRecord!, in: managedContext)
                    }
                }
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
            guard error == nil else {
                return
            }
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            guard error == nil else {
                return
            }
        }
        operation.qualityOfService = .utility
        
        let container = CKContainer.default()
        let db = container.privateCloudDatabase
        db.add(operation)
    }
    
    public static func handleNoteNotification(notification: CKNotification) {
        let serverChangeTokenKey = "ckServerChangeToken"
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        // Use the ChangeToken to fetch only whatever changes have occurred since the last
        // time we asked, since intermediate push notifications might have been dropped.
        var changeToken: CKServerChangeToken? = nil
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        if changeTokenData != nil {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
        }
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken
        let optionsMap = [zoneID: options]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionsMap)
        operation.fetchAllChanges = true
        
        let queryNotification = notification as! CKQueryNotification
        print(queryNotification.queryNotificationReason == .recordCreated)
        print(queryNotification.queryNotificationReason.rawValue)
        operation.recordChangedBlock = { record in
            let queryNotification = notification as! CKQueryNotification
            DispatchQueue.main.async {
                print(queryNotification.queryNotificationReason)
            }
            if queryNotification.queryNotificationReason == .recordUpdated {
                CoreDataHelper.cloudKitNoteChanged(record: record, in: managedContext)
            } else if queryNotification.queryNotificationReason == .recordCreated {
                CoreDataHelper.cloudKitNoteCreated(record: record, in: managedContext)
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            if recordType == "Notes" {
                if queryNotification.queryNotificationReason == .recordDeleted {
                    // try to find the record in coredata
                    let fetchedRecord = CoreDataHelper.fetchNote(with: deletedRecordID.recordName, in: managedContext)
                    
                    if fetchedRecord != nil {
                        CoreDataHelper.delete(note: fetchedRecord!, in: managedContext)
                    }
                }
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
            guard error == nil else {
                return
            }
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            guard error == nil else {
                return
            }
        }
        operation.qualityOfService = .utility
        
        let container = CKContainer.default()
        let db = container.privateCloudDatabase
        db.add(operation)
    }
    
    public static func handleImageNotification(notification: CKNotification) {
        let serverChangeTokenKey = "ckServerChangeToken"
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        // Use the ChangeToken to fetch only whatever changes have occurred since the last
        // time we asked, since intermediate push notifications might have been dropped.
        var changeToken: CKServerChangeToken? = nil
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        if changeTokenData != nil {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
        }
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = changeToken
        let optionsMap = [zoneID: options]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: optionsMap)
        operation.fetchAllChanges = true
        operation.recordChangedBlock = { record in
            DispatchQueue.main.async {
                print(record)
                print("I MADE IT INTO THE RECORD PLACE!!!")
            }
            
            let queryNotification = notification as! CKQueryNotification
            if queryNotification.queryNotificationReason == .recordCreated {
                CoreDataHelper.cloudKitImageCreated(record: record, in: managedContext)
            } else if queryNotification.queryNotificationReason == .recordDeleted {
                CoreDataHelper.cloudKitImageDeleted(record: record, in: managedContext)
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { deletedRecordID, recordType in
            if recordType == "Images" {
                let queryNotification = notification as! CKQueryNotification
                if queryNotification.queryNotificationReason == .recordDeleted {
                    // try to find the record in coredata
                    let fetchedRecord = CoreDataHelper.fetchImage(with: deletedRecordID.recordName, in: managedContext)
                    
                    if fetchedRecord != nil {
                        CoreDataHelper.delete(image: fetchedRecord!, in: managedContext)
                    }
                }
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
            guard error == nil else {
                return
            }
            guard let changeToken = changeToken else {
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            guard error == nil else {
                return
            }
        }
        operation.qualityOfService = .utility
        
        let container = CKContainer.default()
        let db = container.privateCloudDatabase
        db.add(operation)
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        let fetchedRecords = CoreDataHelper.fetchAllRecords(in: managedContext!)
        checkExpiryAndDeletedDates(for: fetchedRecords, context: managedContext!)
        
        warrantiesTableView.reloadData()
        refreshControl.endRefreshing()
        // check if the user is signed in, if not then there is nothing to refresh.
            // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.  Otherwise don't.
//        if !refreshControl.isRefreshing {
//            refreshControl.beginRefreshing()
//        }
//        let conn = UserDefaultsHelper.currentConnection()
//        if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
//            // coredata
//            let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: managedContext!)!
//            
//            var cdRecords = CoreDataHelper.fetchAllRecords(in: managedContext!) // loadAssociatedCDRecords()
//            var cdRecordIDs: [String] = []
//            for record in cdRecords {
//                print(record.recordID! + " " + record.title!)
//                cdRecordIDs.append(record.recordID!)
//            }
//            
//            // cloudkit
//            let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
//            let predicate = NSPredicate(value: true)
//            let query = CKQuery(recordType: "Records", predicate: predicate)
//            
//            print("HANDLING REFRESH !")
//            privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
//                if error != nil {
//                    DispatchQueue.main.async {
//                        print(error.debugDescription)
//                        print("SOMETHING BAD HAPPENED")
//                        self.refreshControl.endRefreshing()
//                    }
//                    return
//                } else {
//                    DispatchQueue.main.async {
//                        print("HANDLING REFRESH 2")
//                    }
//                    
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "MMM d, yyyy"
//                    
//                    for result in results! {
//                        // if record id is in coredata already, sync data to that record
//                        if cdRecordIDs.contains(result.recordID.recordName) {
//                            DispatchQueue.main.async {
//                                print("HANDLING REFRESH 3")
//                            }
//                            let recordIndex = cdRecordIDs.index(of: result.recordID.recordName)
//                            let recordMatch = cdRecords[recordIndex!]
//                            
//                            // check if cloud was synced before local storage
//                            let cloudSynced = result.value(forKey: "lastSynced") as! Date
//                            let localSynced = (recordMatch.lastUpdated ?? Date().addingTimeInterval(-TimeInterval.greatestFiniteMagnitude) as NSDate) as Date
//                            DispatchQueue.main.async {
//                                print(localSynced)
//                            }
//                            if cloudSynced > localSynced {
//                                // sync from cloud to local and pop from cdRecords and cdRecordIDs arrays
//                                DispatchQueue.main.async {
//                                    print("Syncing from cloud to local")
//                                }
//                                let record = recordMatch
//                                
//                                record.dateCreated = result.value(forKey: "dateCreated") as! NSDate?
//                                record.dateDeleted = result.value(forKey: "dateDeleted") as! NSDate?
//                                record.daysBeforeReminder = result.value(forKey: "daysBeforeReminder") as! Int32
//                                record.descriptionString = result.value(forKey: "descriptionString") as! String?
//                                record.eventIdentifier = result.value(forKey: "eventIdentifier") as! String?
//                                record.title = result.value(forKey: "title") as! String?
//                                record.warrantyStarts = dateFormatter.date(from: (result.value(forKey: "warrantyStarts") as! String))! as NSDate
//                                record.warrantyEnds = dateFormatter.date(from: (result.value(forKey: "warrantyEnds") as! String))! as NSDate
//                                DispatchQueue.main.async {
//                                    print("Assigned simple values")
//                                }
//                                
//                                let recentlyDeleted = result.value(forKey: "recentlyDeleted") as! Int64
//                                if recentlyDeleted == 0 {
//                                    record.recentlyDeleted = false
//                                } else {
//                                    record.recentlyDeleted = true
//                                }
//                                let expired = result.value(forKey: "expired") as! Int64
//                                if expired == 0 {
//                                    record.expired = false
//                                } else {
//                                    record.expired = true
//                                }
//                                let hasWarranty = result.value(forKey: "hasWarranty") as! Int64
//                                if hasWarranty == 0 {
//                                    record.hasWarranty = false
//                                } else {
//                                    record.hasWarranty = true
//                                }
//                                record.lastUpdated = Date() as NSDate?
//                                record.recordID = result.recordID.recordName
//                                
//                                DispatchQueue.main.async {
//                                    print("Assigned assets and other values to " + record.recordID!)
//                                }
//                                
//                                // remove updated record from record lists so that once finished, the remainder
//                                // (those not existing on the cloud) can be synced to the cloud.
//                                cdRecords.remove(at: recordIndex!)
//                                cdRecordIDs.remove(at: recordIndex!)
//                                
//                                DispatchQueue.main.async {
//                                    print("HANDLING REFRESH 5")
//                                }
//                            }
//                            
//                            // sync notes and images associated with this record to coredata if they aren't already there
//                            CoreDataHelper.importImagesFromCloudKit(associatedWith: recordMatch, in: self.managedContext!)
//                            CoreDataHelper.importNotesFromCloudKit(associatedWith: recordMatch, in: self.managedContext!)
//                            
//                        } else { // create new record from data in cloud
//                            DispatchQueue.main.async {
//                                print("HANDLING REFRESH 4")
//                            }
//                            let record = NSManagedObject(entity: recordEntity, insertInto: self.managedContext!) as! Record
//                            record.dateDeleted = result.value(forKey: "dateDeleted") as! NSDate?
//                            record.daysBeforeReminder = result.value(forKey: "daysBeforeReminder") as! Int32
//                            record.descriptionString = result.value(forKey: "descriptionString") as! String?
//                            record.eventIdentifier = result.value(forKey: "eventIdentifier") as! String?
//                            record.title = result.value(forKey: "title") as! String?
//                            record.warrantyStarts = dateFormatter.date(from: (result.value(forKey: "warrantyStarts") as! String))! as NSDate
//                            record.warrantyEnds = dateFormatter.date(from: (result.value(forKey: "warrantyEnds") as! String))! as NSDate
//                            
//                            // Bools stored as ints on CK.  Need to be converted
//                            let recentlyDeleted = result.value(forKey: "recentlyDeleted") as! Int64
//                            if recentlyDeleted == 0 {
//                                record.recentlyDeleted = false
//                            } else {
//                                record.recentlyDeleted = true
//                            }
//                            let expired = result.value(forKey: "expired") as! Int64
//                            if expired == 0 {
//                                record.expired = false
//                            } else {
//                                record.expired = true
//                            }
//                            let hasWarranty = result.value(forKey: "hasWarranty") as! Int64
//                            if hasWarranty == 0 {
//                                record.hasWarranty = false
//                            } else {
//                                record.hasWarranty = true
//                            }
//                            record.lastUpdated = Date() as NSDate?
//                            record.recordID = result.recordID.recordName
//                            
//                            CoreDataHelper.importImagesFromCloudKit(associatedWith: record, in: self.managedContext!, tableToRefresh: self.warrantiesTableView)
//                            CoreDataHelper.importNotesFromCloudKit(associatedWith: record, in: self.managedContext!)
//                        }
//                        // Check each note and image in the cloud to check if it has been deleted
//                        self.removeRecentlyDeletedImagesAndNotes(associatedWith: result.recordID, in: self.managedContext!)
//                    }
//                    
//                    CoreDataHelper.save(context: self.managedContext!)
//                    DispatchQueue.main.async {
//                        let fetchedRecords = CoreDataHelper.fetchAllRecords(in: self.managedContext!)
//                        self.checkExpiryAndDeletedDates(for: fetchedRecords, context: self.managedContext!)
//                        self.refreshControl.endRefreshing()
//                        self.warrantiesTableView.reloadData()
//                    }
//                }
//            })
//        } else {
//            // let user know they don't have a connection
//            let alertController = UIAlertController(title: "Destructive", message: "Simple alertView demo with Destructive and Ok.", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
//            let settingsAction = UIAlertAction(title: "Settings", style: UIAlertActionStyle.default) {
//                (result : UIAlertAction) -> Void in
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let settingsController : SettingsTableViewController = storyboard.instantiateViewController(withIdentifier: "settingsController") as! SettingsTableViewController
//                
//                self.navigationController?.pushViewController(settingsController, animated: true)
//            }
//            
//            // Replace UIAlertActionStyle.Default by UIAlertActionStyle.default
//            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) {
//                (result : UIAlertAction) -> Void in
//            }
//            
//            alertController.addAction(settingsAction)
//            alertController.addAction(okAction)
//            self.present(alertController, animated: true, completion: nil)
//        }
    }
    
    func removeRecentlyDeletedImagesAndNotes(associatedWith: CKRecordID, in context: NSManagedObjectContext) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        
        // remove any images that have been deleted recently
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Images", recordID: associatedWith), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                if results != nil {
                    for result in results! {
                        if result.value(forKey: "recentlyDeleted") as! Int != 0 { // if recently deleted
                            DispatchQueue.main.async {
                                //print("CK record to delete: \(result.recordID.recordName)")
                            }
                            // find in coredata and delete
                            let deletedRecord: Image? = CoreDataHelper.fetchImage(with: result.recordID.recordName, in: context)
                            
                            if deletedRecord != nil {
                                CoreDataHelper.delete(image: deletedRecord!, in: context)
                                
                                DispatchQueue.main.async {
                                    print("Successfully deleted)")
                                }
                            }
                        }
                    }
                }
            }
        })
        
        // remove any notes that have been deleted recently
        let notesPredicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Notes", recordID: associatedWith), action: CKReferenceAction.deleteSelf))
        let notesQuery = CKQuery(recordType: "Notes", predicate: notesPredicate)
        
        privateDatabase.perform(notesQuery, inZoneWith: nil, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                if results != nil {
                    for result in results! {
                        if result.value(forKey: "recentlyDeleted") as! Int != 0 { // if recently deleted
                            DispatchQueue.main.async {
                                //print("CK record to delete: \(result.recordID.recordName)")
                            }
                            // find in coredata and delete
                            let deletedNote: Note? = CoreDataHelper.fetchNote(with: result.recordID.recordName, in: context)
                            
                            if deletedNote != nil {
                                CoreDataHelper.delete(note: deletedNote!, in: context)
                                
                                DispatchQueue.main.async {
                                    print("Successfully deleted)")
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        //configureButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let fetchedRecords = CoreDataHelper.fetchAllRecords(in: managedContext!)
        checkExpiryAndDeletedDates(for: fetchedRecords, context: managedContext!)
        
        navigationController?.isToolbarHidden = false
        navigationController?.view.clipsToBounds = true
        navigationController?.view.layer.masksToBounds = true
        navigationController?.view.layer.cornerRadius = 8
        
        self.warrantiesTableView.reloadData()
    }
    
    @IBAction func selectedSegmentChanged(_ sender: Any) {
        self.warrantiesTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        generator.impactOccurred()
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row]
            performSegue(withIdentifier: "toCellDetails", sender: self)
        } else {
            selectedRecord = records[indexPath.row]
            performSegue(withIdentifier: "toCellDetails", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        print("\nTable View is Reloading\n")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if searchActive {
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                filteredRecords.sort(by:{ $0.dateCreated?.compare($1.dateCreated! as Date) == .orderedDescending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                    cell.photoLoadingIndicator.stopAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                    //cell.photoLoadingIndicator.startAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                }
            } else {
                filteredRecords.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds! as Date) == .orderedAscending})
                let record = filteredRecords[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                    cell.photoLoadingIndicator.stopAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                    //cell.photoLoadingIndicator.startAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                }
            }
        } else {
            if sortBySegmentControl.selectedSegmentIndex == 0 {
                records.sort(by:{ $0.dateCreated?.compare($1.dateCreated! as Date) == .orderedDescending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    print(recordImage)
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                    cell.photoLoadingIndicator.stopAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                    //cell.photoLoadingIndicator.startAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                }
            } else {
                records.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds! as Date) == .orderedAscending})
                let record = records[indexPath.row]
                cell.title.text = record.title
                //cell.descriptionView.text = record.descriptionString
                cell.warrantyStarts.text = dateFormatter.string(from: record.warrantyStarts! as Date)
                if !record.hasWarranty {
                    cell.warrantyEnds.text = dateFormatter.string(from: record.warrantyEnds! as Date)
                } else {
                    cell.warrantyEnds.text = "∞"
                }
                let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
                if fetchedImages.count > 0 {
                    let recordImage = fetchedImages[0]
                    cell.warrantyImageView.image = UIImage(data: recordImage.image! as Data)
                    cell.photoLoadingIndicator.stopAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                    //cell.photoLoadingIndicator.startAnimating()
                    cell.photoLoadingIndicator.isHidden = true
                }
            }
            
        }
        
        cell.warrantyImageView.contentMode = .scaleAspectFit
        cell.title.textColor = cell.tintColor
        cell.backgroundColor = UIColor(colorLiteralRed: 189, green: 195, blue: 201, alpha: 1.0)
        cell.warrantyImageView.layer.cornerRadius = 15
        cell.warrantyImageView.layer.masksToBounds = true
        
        lastCell = cell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return filteredRecords.count
        } else {
            return records.count
        }
    }
    
    func reloadLastControllerTableView() {
        DispatchQueue.main.async() {
            let fetchedRecords = CoreDataHelper.fetchAllRecords(in: self.managedContext!)
            self.checkExpiryAndDeletedDates(for: fetchedRecords, context: self.managedContext!)
            self.warrantiesTableView.reloadData()
        }
    }
    
    func checkExpiryAndDeletedDates(for recordsArray: [Record], context: NSManagedObjectContext) {
        records = []
        for eachRecord in recordsArray {
            let calendar = NSCalendar.current
            if eachRecord.recentlyDeleted {
                // Replace the hour (time) of both dates with 00:00
                let deletedDate = calendar.startOfDay(for: eachRecord.dateDeleted! as Date)
                let currentDate = calendar.startOfDay(for: Date())
                
                let components = calendar.dateComponents([.day], from: deletedDate, to: currentDate)
                
                if components.day! > 30 { // This will return the number of day(s) between dates
                    do {
                        context.delete(eachRecord)
                        try context.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                }
            } else { // add to active records list
                // Replace the hour (time) of both dates with 00:00
                let expiryDate = calendar.startOfDay(for: eachRecord.warrantyEnds! as Date)
                let currentDate = calendar.startOfDay(for: Date())
                
                let components = calendar.dateComponents([.day], from: expiryDate, to: currentDate)
                
                if components.day! > 0 { // This will return the number of day(s) between dates
                    do {
                        eachRecord.expired = true
                        try context.save()
                    } catch {
                        print("Record could not be deleted")
                    }
                } else {
                    records.append(eachRecord)
                }
            }
        }
    }
    
    func getRecordsFromCloudKit() {
        
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        
        let recordsPredicate = NSPredicate(value: true)
        let recordsQuery = CKQuery(recordType: "Records", predicate: recordsPredicate)
        privateDatabase.perform(recordsQuery, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error retrieving records from cloudkit")
            } else {
                if (results?.count)! > 0 {
                    // compare with core data records JEFF
                }
            }
        })
        
    }
    
    //MARK: Search bar delegate functions
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
        warrantiesTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredRecords = []
        for record in records {
            let currentRecord = record
            if (currentRecord.title?.lowercased().contains(searchText.lowercased()))! && !filteredRecords.contains(currentRecord) {
                filteredRecords.append(currentRecord)
            }
        }
        
        if (searchText == "") {
            searchActive = false;
        } else {
            searchActive = true;
        }
        warrantiesTableView.reloadData()
    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = warrantiesTableView.convert(location, from: self.view)
        
        guard let indexPath = warrantiesTableView.indexPathForRow(at: cellPosition),
            let cell = warrantiesTableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        guard let detailViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "DetailsTableViewController") as?
            DetailsTableViewController else {
            return nil
        }
        
        if searchActive {
            selectedRecord = filteredRecords[indexPath.row]
        } else {
            selectedRecord = records[indexPath.row]
        }
        
        detailViewController.reloadDelegate = self
        detailViewController.record = selectedRecord
        detailViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(cell.frame, from: warrantiesTableView)
        
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    @IBAction func unwindToInitialController(segue: UIStoryboardSegue){}
    
    // MARK: Prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toCellDetails") {
            if let nextViewController = segue.destination as? DetailsTableViewController {
                if (selectedRecord != nil) {
                    nextViewController.record = selectedRecord
                } else {
                    print("Selected Record was nil")
                }
            }
        }
    }
    
    //MARK: Network Connectivity Tests
    func updateUserInterface() {
        guard let status = Network.reachability?.status else { return }
        switch status {
        case .unreachable:
            defaults.set("unreachable", forKey: "connection")
        case .wifi:
            defaults.set("wifi", forKey: "connection")
            syncEverything()
            
        case .wwan:
            defaults.set("data", forKey: "connection")
            if UserDefaultsHelper.canSyncUsingData() {
                syncEverything() // there should only be anything in the queued array if the user is just coming out of an area of no service.
            }
        }
        print("Reachability Summary")
        print("Status:", status)
        print("HostName:", Network.reachability?.hostname ?? "nil")
        print("Reachable:", Network.reachability?.isReachable ?? "nil")
        print("Wifi:", Network.reachability?.isReachableViaWiFi ?? "nil")
    }
    func statusManager(_ notification: NSNotification) {
            updateUserInterface()
    }
    
    func syncEverything() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let queuedRecords = UserDefaultsHelper.getQueuedChanges()
        let queuedRecordsToDelete = UserDefaultsHelper.getQueuedToDelete()
        
        if queuedRecords != nil {
            if (queuedRecords?.count)! > 0 {
                for recordID in queuedRecords! {
                    
                    let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
                    privateDatabase.fetch(withRecordID: CKRecordID(recordName: recordID, zoneID: zoneID), completionHandler: ({record, error in
                        let fetchedRecord = CoreDataHelper.fetchRecord(with: recordID, in: managedContext) as Record?
                        if let err = error {
                            DispatchQueue.main.async() {
                                print(err.localizedDescription)
                                print("Syncing as new record to cloud.")
                            }
                            // couldn't find record, save in cloud as new record
                            CloudKitHelper.importCDRecord(cdRecord: fetchedRecord!, context: managedContext)
                        } else { // found record, update it in cloud
                            CloudKitHelper.updateRecordInCloudKit(cdRecord: fetchedRecord!, context: managedContext)
                        }
                    }))
                }
                UserDefaultsHelper.setQueueToEmpty()
            }
        }
        
        if queuedRecordsToDelete != nil {
            if (queuedRecordsToDelete?.count)! > 0 {
                for recordID in queuedRecordsToDelete! {
                    
                    let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
                    privateDatabase.delete(withRecordID: CKRecordID(recordName: recordID, zoneID: zoneID), completionHandler: ({record, error in
                        if let err = error {
                            DispatchQueue.main.async() {
                                print(err.localizedDescription)
                                print("Syncing as new record to cloud.")
                            }
                            // couldn't find record, save in cloud as new record
                        } else { // found record, update it in cloud
                            
                        }
                    }))
                }
                UserDefaultsHelper.setQueueToEmpty()
            }
        }
    }
}

