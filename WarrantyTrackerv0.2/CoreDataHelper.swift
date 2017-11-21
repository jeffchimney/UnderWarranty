//
//  CoreDataHelper.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-03-06.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import EventKit

class CoreDataHelper {
    
    static func recordCount(in context: NSManagedObjectContext) -> Int {
        // Get associated images
        let recordFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        var count = 0
        do {
            count = try context.count(for: recordFetchRequest)
        } catch let error as NSError {
            count = 0
            print("Could not count records. \(error), \(error.userInfo)")
        }
        
        return count
    }
    
    static func fetchAllRecords(in context: NSManagedObjectContext) -> [Record] {
        // Get associated images
        let recordFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        var recordRecords: [NSManagedObject] = []
        do {
            recordRecords = try context.fetch(recordFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var recordList: [Record] = []
        for record in recordRecords {
            let thisRecord = record as! Record
            
            recordList.append(thisRecord)
        }
        return recordList
    }
    
//    static func fetchRecord(with id: String, in context: NSManagedObjectContext) -> Record {
//        let predicate = NSPredicate(format: "recordID = %@", id)
//
//        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Record")
//        fetchRequest.predicate = predicate
//
//        var returnedRecords: [NSManagedObject] = []
//        do {
//            returnedRecords = try context.fetch(fetchRequest)
//        } catch let error as NSError {
//            print("Could not fetch. \(error), \(error.userInfo)")
//        }
//        let record = returnedRecords[0] as! Record
//
//        return record
//    }
    
    static func fetchRecord(with id: String, in context: NSManagedObjectContext) -> Record? {
        let predicate = NSPredicate(format: "recordID = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Record")
        fetchRequest.predicate = predicate
        
        var returnedRecords: [NSManagedObject] = []
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if returnedRecords.count > 0 {
            let record = returnedRecords[0] as! Record
            
            return record
        } else {
            return nil
        }
    }
    
    static func fetchImage(with id: String, in context: NSManagedObjectContext) -> Image? {
        let predicate = NSPredicate(format: "id = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Image")
        fetchRequest.predicate = predicate
        
        var returnedImages: [NSManagedObject] = []
        do {
            returnedImages = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        if returnedImages.count > 0 {
            let image = returnedImages[0] as! Image
            
            return image
        } else {
            return nil
        }
    }
    
    static func fetchImages(for record: Record, in context: NSManagedObjectContext) -> [Image] {
        // Get associated images
        let imageFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Image")
        let predicate = NSPredicate(format: "record = %@", record)
        imageFetchRequest.predicate = predicate
        
        var imageRecords: [NSManagedObject] = []
        do {
            imageRecords = try context.fetch(imageFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var imageList: [Image] = []
        for image in imageRecords {
            let thisImage = image as! Image
            
            imageList.append(thisImage)
        }
        return imageList
    }
    
    static func fetchNote(with id: String, in context: NSManagedObjectContext) -> Note? {
        let predicate = NSPredicate(format: "id = %@", id)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        fetchRequest.predicate = predicate
        
        var returnedNotes: [NSManagedObject] = []
        do {
            returnedNotes = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
        if returnedNotes.count > 0 {
            let note = returnedNotes[0] as! Note
            
            return note
        } else {
            return nil
        }
    }
    
    static func fetchNotes(for record: Record, in context: NSManagedObjectContext) -> [Note] {
        // Get associated notes
        let noteFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Note")
        let predicate = NSPredicate(format: "record = %@", record)
        noteFetchRequest.predicate = predicate
        
        var noteRecords: [NSManagedObject] = []
        do {
            noteRecords = try context.fetch(noteFetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        var noteList: [Note] = []
        for note in noteRecords {
            let thisNote = note as! Note
            
            noteList.append(thisNote)
        }
        return noteList
    }
    
    static func save(context: NSManagedObjectContext) {
        // save locally
        do {
            try context.save()
        } catch {
            DispatchQueue.main.async {
                print("Connection error. Try again later.")
            }
            return
        }
    }
    
    static func delete(record: Record, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                context.delete(thisRecord)
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func delete(note: Note, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Note")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if note == thisRecord {
                context.delete(thisRecord)
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func delete(image: Image, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Image")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if image == thisRecord {
                context.delete(thisRecord)
                do {
                    try context.save()
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func deleteAll() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let context = appDelegate.persistentContainer.viewContext
        let entityList = ["Note", "Tag", "Image", "Record", "Account"]
        
        for entity in entityList {
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
                print (entity + "s were successfully deleted.")
            } catch {
                print ("There was an error deleting " + entity)
            }
        }
    }
    
    static func setRecentlyDeletedFalse(for record: Record, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                let thisRecord = thisRecord as! Record
                thisRecord.recentlyDeleted = false
                do {
                    try context.save()
                    // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                    let conn = UserDefaultsHelper.currentConnection()
                    if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                        CloudKitHelper.updateRecordInCloudKit(cdRecord: record, context: context)
                    } else {
                        // queue up the record to sync when you have a good connection
                        UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                    }
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func setRecentlyDeletedTrue(for record: Record, in context: NSManagedObjectContext) {
        var returnedRecords: [NSManagedObject] = []
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Record")
        
        do {
            returnedRecords = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for thisRecord in returnedRecords {
            if record == thisRecord {
                let thisRecord = thisRecord as! Record
                thisRecord.recentlyDeleted = true
                do {
                    try context.save()
                    // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                    let conn = UserDefaultsHelper.currentConnection()
                    if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                        CloudKitHelper.updateRecordInCloudKit(cdRecord: record, context: context)
                    } else {
                        // queue up the record to sync when you have a good connection
                        UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                    }
                } catch {
                    print("Error deleting record")
                }
            }
        }
    }
    
    static func importNotesFromCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@ AND recentlyDeleted = 0", CKReference(record: CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Notes", predicate: predicate)
        
        let localNoteRecords = fetchNotes(for: associatedWith, in: context)
        var localNoteIDs: [String] = []
        for noteRecord in localNoteRecords {
            localNoteIDs.append(noteRecord.id!)
        }
        publicDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                // pare down results that already exist in the cloud
                for result in results! {
                    let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: context)!
                    let note = NSManagedObject(entity: noteEntity, insertInto: context) as! Note
                    
                    if result.object(forKey: "recentlyDeleted") as! Int == 0 && !localNoteIDs.contains(result.recordID.recordName) { // if !recentlyDeleted, add to coredata
                        note.id = result.recordID.recordName
                        note.lastSynced = Date() as NSDate
                        note.title = result.value(forKey: "title") as? String
                        note.noteString = result.value(forKey: "noteString") as? String
                        print(associatedWith.title)
                        note.record = associatedWith
                        
                        // save locally
                        do {
                            try context.save()
                            DispatchQueue.main.async {
                                print("Imported notes to core data")
                            }
                        } catch {
                            DispatchQueue.main.async {
                                print("Error importing notes to core data")
                            }
                            return
                        }
                    }
                }
            }
        })
    }
    
    static func importImagesFromCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@ AND recentlyDeleted = 0", CKReference(record: CKRecord(recordType: "Images", recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        let localImageRecords = fetchImages(for: associatedWith, in: context)
        var localImageIDs: [String] = []
        for imageRecord in localImageRecords {
            localImageIDs.append(imageRecord.id!)
        }
        
        publicDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                // pare down results that already exist in the cloud
                for result in results! {
                    
                    if result.value(forKey: "recentlyDeleted") as! Int == 0 && !localImageIDs.contains(result.recordID.recordName) { // if !recentlyDeleted and doesnt already exist in coredata, add to coredata
                        let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)!
                        
                        let image = NSManagedObject(entity: imageEntity, insertInto: context) as! Image

                        image.lastSynced = Date() as NSDate

                        // CKAssets need to be converted to NSData
                        let imageData = result.value(forKey: "image") as! CKAsset
                        
                        image.image = NSData(contentsOf: imageData.fileURL)
                        
                        image.id = result.recordID.recordName
                        image.record = associatedWith
                        
                        // save locally
                        do {
                            try context.save()
                            DispatchQueue.main.async {
                                print("Imported images to core data")
                            }
                        } catch {
                            DispatchQueue.main.async {
                                print("Error importing images to core data")
                            }
                            return
                        }
                    }
                }
            }
        })
    }
    
    static func importImagesFromCloudKit(associatedWith: Record, in context: NSManagedObjectContext, tableToRefresh: UITableView) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let publicDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@ AND recentlyDeleted = 0", CKReference(record: CKRecord(recordType: "Images", recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        let localImageRecords = fetchImages(for: associatedWith, in: context)
        var localImageIDs: [String] = []
        for imageRecord in localImageRecords {
            localImageIDs.append(imageRecord.id!)
        }
        
        publicDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                // pare down results that already exist in the cloud
                for result in results! {
                    
                    if result.value(forKey: "recentlyDeleted") as! Int == 0 && !localImageIDs.contains(result.recordID.recordName) { // if !recentlyDeleted and doesnt already exist in coredata, add to coredata
                        let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)!
                        
                        let image = NSManagedObject(entity: imageEntity, insertInto: context) as! Image
                        
                        image.lastSynced = Date() as NSDate
                        
                        // CKAssets need to be converted to NSData
                        let imageData = result.value(forKey: "image") as! CKAsset
                        
                        image.image = NSData(contentsOf: imageData.fileURL)
                        
                        image.id = result.recordID.recordName
                        image.record = associatedWith
                        
                        // save locally
                        do {
                            try context.save()
                            DispatchQueue.main.async {
                                tableToRefresh.reloadData()
                                print("Imported images to core data")
                            }
                        } catch {
                            DispatchQueue.main.async {
                                print("Error importing images to core data")
                            }
                            return
                        }
                    }
                }
            }
        })
    }
    
    static func cloudKitRecordChanged(record: CKRecord, in context: NSManagedObjectContext) {//, reload: UITableView) {
        //CloudKitHelper.fetchAndUpdateLocalRecord(recordID: record.recordID, in: context)
        let fetchedRecord = fetchRecord(with: record.recordID.recordName, in: context)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        fetchedRecord!.daysBeforeReminder = record.value(forKey: "daysBeforeReminder") as! Int32
        fetchedRecord!.descriptionString = record.value(forKey: "descriptionString") as! String?
        fetchedRecord!.eventIdentifier = record.value(forKey: "eventIdentifier") as! String?
        fetchedRecord!.title = record.value(forKey: "title") as! String?
        fetchedRecord!.warrantyStarts = dateFormatter.date(from: (record.value(forKey: "warrantyStarts") as! String))! as NSDate
        fetchedRecord!.warrantyEnds = dateFormatter.date(from: (record.value(forKey: "warrantyEnds") as! String))! as NSDate
        DispatchQueue.main.async {
            print("Assigned simple values")
        }
        
        // Bools stored as ints on CK.  Need to be converted
        let recentlyDeleted = record.value(forKey: "recentlyDeleted") as! Int64
        if recentlyDeleted == 0 {
            fetchedRecord!.recentlyDeleted = false
        } else {
            fetchedRecord!.recentlyDeleted = true
            fetchedRecord!.dateDeleted = dateFormatter.date(from: (record.value(forKey: "dateDeleted") as! String))! as NSDate
        }
        let expired = record.value(forKey: "expired") as! Int64
        if expired == 0 {
            fetchedRecord!.expired = false
        } else {
            fetchedRecord!.expired = true
        }
        let hasWarranty = record.value(forKey: "hasWarranty") as! Int64
        if hasWarranty == 0 {
            fetchedRecord!.hasWarranty = false
        } else {
            fetchedRecord!.hasWarranty = true
        }
        fetchedRecord!.dateCreated = record.creationDate! as NSDate
        fetchedRecord!.lastUpdated = Date() as NSDate?
        fetchedRecord!.recordID = record.recordID.recordName
        do {
            try context.save()
            DispatchQueue.main.async {
                print("Synced Changes to Note to Core Data")
            }
        } catch {
            DispatchQueue.main.async {
                print("Error Syncing Changes to Note to Core Data")
            }
            return
        }
        
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        if !fetchedRecord!.hasWarranty {
            if EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                for calendar in calendars {
                    if calendar.title == "UnderWarranty" {
                        var event = eventStore.event(withIdentifier: fetchedRecord!.eventIdentifier!)
                        if event == nil {
                            event = EKEvent(eventStore: eventStore)
                            event?.calendar = calendar
                            event?.title = fetchedRecord!.title! + " Warranty Expires"
                            event?.notes = "Is your item still working properly?  Its warranty expires today."
                        }
                        event?.startDate = fetchedRecord!.warrantyEnds! as Date
                        let endDate = fetchedRecord!.warrantyEnds! as Date
                        event?.endDate = endDate
                        event?.isAllDay = true
                        
                        // remove old alarm and configure new alarm for event
                        if (event?.hasAlarms)! {
                            event?.alarms?.removeAll()
                        }
                        
                        let daysToSubtract = Int(-fetchedRecord!.daysBeforeReminder)
                        
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
            }
        }
    }
    
    static func cloudKitRecordCreated(record: CKRecord, in context: NSManagedObjectContext) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        let recordEntity = NSEntityDescription.entity(forEntityName: "Record", in: context)!
        let cdRecord = NSManagedObject(entity: recordEntity, insertInto: context) as! Record
        
        cdRecord.daysBeforeReminder = record.value(forKey: "daysBeforeReminder") as! Int32
        cdRecord.descriptionString = record.value(forKey: "descriptionString") as! String?
        cdRecord.eventIdentifier = record.value(forKey: "eventIdentifier") as! String?
        cdRecord.title = record.value(forKey: "title") as! String?
        cdRecord.warrantyStarts = dateFormatter.date(from: (record.value(forKey: "warrantyStarts") as! String))! as NSDate
        cdRecord.warrantyEnds = dateFormatter.date(from: (record.value(forKey: "warrantyEnds") as! String))! as NSDate
        DispatchQueue.main.async {
            print("Assigned simple values")
        }
        
        let recentlyDeleted = record.value(forKey: "recentlyDeleted") as! Int64
        if recentlyDeleted == 0 {
            cdRecord.recentlyDeleted = false
        } else {
            cdRecord.recentlyDeleted = true
            cdRecord.dateDeleted = dateFormatter.date(from: (record.value(forKey: "dateDeleted") as! String))! as NSDate
        }
        let expired = record.value(forKey: "expired") as! Int64
        if expired == 0 {
            cdRecord.expired = false
        } else {
            cdRecord.expired = true
        }
        let hasWarranty = record.value(forKey: "hasWarranty") as! Int64
        if hasWarranty == 0 {
            cdRecord.hasWarranty = false
        } else {
            cdRecord.hasWarranty = true
        }
        cdRecord.dateCreated = record.creationDate! as NSDate
        cdRecord.lastUpdated = Date() as NSDate?
        cdRecord.recordID = record.recordID.recordName
        
        do {
            try context.save()
            DispatchQueue.main.async {
                print("Synced Changes to Note to Core Data")
            }
        } catch {
            DispatchQueue.main.async {
                print("Error Syncing Changes to Note to Core Data")
            }
            return
        }
        
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        if !cdRecord.hasWarranty {
            if EKEventStore.authorizationStatus(for: EKEntityType.event) == .authorized {
                for calendar in calendars {
                    if calendar.title == "UnderWarranty" {
                        let event = EKEvent(eventStore: eventStore)
                        event.calendar = calendar
                        event.title = cdRecord.title! + " Warranty Expires"
                        event.notes = "Is your item still working properly?  Its warranty expires today."
                        
                        event.startDate = cdRecord.warrantyEnds! as Date
                        let endDate = cdRecord.warrantyEnds! as Date
                        event.endDate = endDate
                        event.isAllDay = true
                        
                        // remove old alarm and configure new alarm for event
                        if (event.hasAlarms) {
                            event.alarms?.removeAll()
                        }
                        
                        let daysToSubtract = Int(-cdRecord.daysBeforeReminder)
                        
                        var addingPeriod = DateComponents()
                        addingPeriod.day = daysToSubtract
                        addingPeriod.hour = 12
                        
                        let userCalendar = NSCalendar.current
                        let alarmDate = userCalendar.date(byAdding: addingPeriod, to: endDate) // this is really subtracting...
                        
                        let alarm = EKAlarm(absoluteDate: alarmDate!)
                        event.addAlarm(alarm)
                        
                        do {
                            try eventStore.save(event, span: .thisEvent, commit: true)
                        } catch {
                            print("The event couldnt be updated")
                        }
                    }
                }
            }
        }
    }
    
    static func cloudKitRecordDeleted(record: CKRecord, in context: NSManagedObjectContext) {
        // try to find the record in coredata
        let fetchedRecord = fetchRecord(with: record.recordID.recordName, in: context)
        
        delete(record: fetchedRecord!, in: context)
    }
    
    static func cloudKitNoteChanged(record: CKRecord, in context: NSManagedObjectContext) {
        // try to find the note in coredata
        let fetchedRecord = fetchNote(with: record.recordID.recordName, in: context)
        if fetchedRecord != nil { // update note
            let (title, noteString) = syncToNote(record: record)
            fetchedRecord?.title = title
            fetchedRecord?.noteString = noteString
            do {
                try context.save()
                DispatchQueue.main.async {
                    print("Synced Changes to Note to Core Data")
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error Syncing Changes to Note to Core Data")
                }
                return
            }
        } else { // create new note
            cloudKitNoteCreated(record: record, in: context)
        }
    }
    
    static func cloudKitNoteCreated(record: CKRecord, in context: NSManagedObjectContext) {
        // try to find the record in coredata
        let noteEntity = NSEntityDescription.entity(forEntityName: "Note", in: context)!
        let cdNote = NSManagedObject(entity: noteEntity, insertInto: context) as! Note
        let ckAssociatedRecord = record.value(forKey: "associatedRecord") as! CKReference
        print(ckAssociatedRecord.recordID.recordName)
        let cdAssociatedRecord = fetchRecord(with: ckAssociatedRecord.recordID.recordName.trimmingCharacters(in: .whitespacesAndNewlines), in: context)
        
        let (title, noteString) = syncToNote(record: record)
        cdNote.id = record.recordID.recordName
        cdNote.record = cdAssociatedRecord!
        cdNote.title = title
        cdNote.noteString = noteString
        do {
            try context.save()
            DispatchQueue.main.async {
                print("Synced Changes to Note to Core Data")
            }
        } catch {
            DispatchQueue.main.async {
                print("Error Syncing Changes to Note to Core Data")
            }
            return
        }
    }
    
    static func cloudKitNoteDeleted(record: CKRecord, in context: NSManagedObjectContext) {
        // try to find the record in coredata
        let fetchedRecord = fetchNote(with: record.recordID.recordName, in: context)

        if fetchedRecord != nil {
            delete(note: fetchedRecord!, in: context)
        }
    }
    
    static func cloudKitImageCreated(record: CKRecord, in context: NSManagedObjectContext) {
        // try to find the record in coredata
        // try to find the record in coredata
        let noteEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)!
        let cdImage = NSManagedObject(entity: noteEntity, insertInto: context) as! Image
        let ckAssociatedRecord = record.value(forKey: "associatedRecord") as! CKReference
        print(ckAssociatedRecord.recordID.recordName)
        let cdAssociatedRecord = fetchRecord(with: ckAssociatedRecord.recordID.recordName.trimmingCharacters(in: .whitespacesAndNewlines), in: context)
        
        
        cdImage.id = record.recordID.recordName
        cdImage.record = cdAssociatedRecord!
        let imageData = record.value(forKey: "image") as! CKAsset
        cdImage.image = NSData(contentsOf: imageData.fileURL)
        cdImage.lastSynced = Date() as NSDate
        do {
            try context.save()
            DispatchQueue.main.async {
                print("Synced Changes to Note to Core Data")
            }
        } catch {
            DispatchQueue.main.async {
                print("Error Syncing Changes to Note to Core Data")
            }
            return
        }
    }
    
    static func cloudKitImageDeleted(record: CKRecord, in context: NSManagedObjectContext) {
        let fetchedRecord = fetchImage(with: record.recordID.recordName, in: context)

        if fetchedRecord != nil {
            delete(image: fetchedRecord!, in: context)
        }
    }
    
    static func syncToNote(record: CKRecord) -> (String?, String?) {
        let title = record["title"] as? String
        guard title != nil else {
            return (nil, nil)
        }
        
        // CKAsset data is stored as a local temporary file. Read it
        // into a String here.
        let noteString = record["noteString"] as? String
        guard title != nil else {
            return (nil, nil)
        }
        
        return (title, noteString)
    }
}
