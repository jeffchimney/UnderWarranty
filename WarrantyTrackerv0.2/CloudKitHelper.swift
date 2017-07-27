`//
//  CloudKitHelper.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-03-06.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import CloudKit
import CoreData


class CloudKitHelper {
    
    static func fetchRecord(recordID: CKRecordID) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        privateDatabase.fetch(withRecordID: recordID, completionHandler: ({record, error in
            if let err = error {
                DispatchQueue.main.async() {
                    print(err.localizedDescription)
                }
            } else {
                // found record
            }
        }))
    }
    
    static func importCDRecord(cdRecord: Record, context: NSManagedObjectContext) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Records", predicate: predicate)
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error retrieving from cloudkit")
            } else {
                    
                let ckRecord = CKRecord(recordType: "Records", recordID: CKRecordID(recordName: cdRecord.recordID!, zoneID: zoneID))
                
                ckRecord.setObject(cdRecord.title! as CKRecordValue?, forKey: "title")
                ckRecord.setObject(cdRecord.descriptionString! as CKRecordValue?, forKey: "descriptionString")
                ckRecord.setObject(cdRecord.warrantyStarts, forKey: "warrantyStarts")
                ckRecord.setObject(cdRecord.warrantyEnds, forKey: "warrantyEnds")
                ckRecord.setObject(cdRecord.eventIdentifier! as CKRecordValue, forKey: "eventIdentifier")
                ckRecord.setObject(cdRecord.daysBeforeReminder as CKRecordValue?, forKey: "daysBeforeReminder")
                ckRecord.setObject(cdRecord.hasWarranty as CKRecordValue?, forKey: "hasWarranty")
                ckRecord.setObject(cdRecord.dateCreated as CKRecordValue?, forKey: "dateCreated")
                ckRecord.setObject(cdRecord.recentlyDeleted as CKRecordValue?, forKey: "recentlyDeleted")
                ckRecord.setObject(cdRecord.expired as CKRecordValue?, forKey: "expired")
                let syncedDate = Date()
                ckRecord.setObject(syncedDate as CKRecordValue?, forKey: "lastSynced")
                
                if cdRecord.recentlyDeleted {
                    ckRecord.setObject(cdRecord.dateDeleted as CKRecordValue?, forKey: "dateDeleted")
                }
                
                privateDatabase.save(ckRecord, completionHandler: { (record, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    print("Successfully added record")
                    
                    self.importAssociatedImages(cdRecord: cdRecord, syncedDate: syncedDate, context: context)
                    self.importAssociatedNotes(cdRecord: cdRecord, syncedDate: syncedDate, context: context)
                })
            }
        })
    }
    
    static func updateRecordInCloudKit(cdRecord: Record, context: NSManagedObjectContext) {
     let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let recordsPredicate = NSPredicate(format: "%K == %@", "recordID" ,CKReference(recordID: CKRecordID(recordName: cdRecord.recordID!, zoneID: zoneID), action: .none))
        let query = CKQuery(recordType: "Records", predicate: recordsPredicate)
        
        privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                DispatchQueue.main.async {
                    print("Error retrieving from cloudkit")
                }
            } else {
                if (results?.count)! > 0 {
                    let ckRecord = (results?[0])!
                    
                    ckRecord.setObject(cdRecord.title! as CKRecordValue?, forKey: "title")
                    ckRecord.setObject(cdRecord.descriptionString! as CKRecordValue?, forKey: "descriptionString")
                    ckRecord.setObject(cdRecord.warrantyStarts, forKey: "warrantyStarts")
                    ckRecord.setObject(cdRecord.warrantyEnds, forKey: "warrantyEnds")
                    ckRecord.setObject(cdRecord.daysBeforeReminder as CKRecordValue?, forKey: "daysBeforeReminder")
                    ckRecord.setObject(cdRecord.hasWarranty as CKRecordValue?, forKey: "hasWarranty")
                    ckRecord.setObject(cdRecord.dateCreated as CKRecordValue?, forKey: "dateCreated")
                    ckRecord.setObject(cdRecord.recentlyDeleted as CKRecordValue?, forKey: "recentlyDeleted")
                    ckRecord.setObject(cdRecord.expired as CKRecordValue?, forKey: "expired")
                    let syncedDate = Date()
                    ckRecord.setObject(syncedDate as CKRecordValue?, forKey: "lastSynced")
                    
                    if cdRecord.recentlyDeleted {
                        ckRecord.setObject(cdRecord.dateDeleted as CKRecordValue?, forKey: "dateDeleted")
                    }
                    
                    privateDatabase.save(ckRecord, completionHandler: { (record, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        DispatchQueue.main.async {
                            print("Successfully updated record")
                        }
                        self.syncImagesToCloudKit(associatedWith: cdRecord, in: context)
                        self.syncNotesToCloudKit(associatedWith: cdRecord, in: context)
                    })
                }
            }
        })
    }
    
    static func syncImagesToCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Images", recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Images", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                var cdImageRecords = CoreDataHelper.fetchImages(for: associatedWith, in: context)
                var cdImageRecordIDs: [String] = []
                for imageRecord in cdImageRecords {
                    cdImageRecordIDs.append(imageRecord.id!)
                }
                
                // pare down results that already exist in the cloud
                if results != nil {
                    for result in results! {
                        let resultID = result.value(forKey: "id") as! String
                        if cdImageRecordIDs.contains(resultID) {
                            let index = cdImageRecordIDs.index(of: resultID)
                            cdImageRecordIDs.remove(at: index!)
                            cdImageRecords.remove(at: index!)
                        }
                    }
                }
                
                // sync remaining records to cloudkit
                for image in cdImageRecords {
                    let ckImage = CKRecord(recordType: "Images", recordID: CKRecordID(recordName: image.id!, zoneID: zoneID))
                    
                    let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
                    let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                    do {
                        try image.image!.write(to: url, options: NSData.WritingOptions.atomicWrite)
                        
                        let imageAsset = CKAsset(fileURL: url)
                        
                        ckImage.setObject(imageAsset, forKey: "image")
                        
                        let reference = CKReference(recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
                        ckImage.setObject(reference, forKey: "associatedRecord")
                        ckImage.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
                        ckImage.setObject(image.id as CKRecordValue?, forKey: "id")
                        
                        privateDatabase.save(ckImage, completionHandler: { (record, error) in
                            if error != nil {
                                print(error!)
                                return
                            }
                        })
                    } catch {
                        DispatchQueue.main.async {
                            print("Problems writing image data to URL")
                        }
                    }
                }
            }
        })
    }
    
    static func syncNotesToCloudKit(associatedWith: Record, in context: NSManagedObjectContext) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let predicate = NSPredicate(format: "associatedRecord = %@", CKReference(record: CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID)), action: CKReferenceAction.deleteSelf))
        let query = CKQuery(recordType: "Notes", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
            if error != nil {
                print("Error pulling from CloudKit")
            } else {
                var cdNotesRecords = CoreDataHelper.fetchNotes(for: associatedWith, in: context)
                var cdNotesRecordIDs: [String] = []
                for noteRecord in cdNotesRecords {
                    cdNotesRecordIDs.append(noteRecord.id!)
                }

                // pare down results that already exist in the cloud
                if results != nil {
                    for result in results! {
                        let resultID = result.recordID.recordName
                        if cdNotesRecordIDs.contains(resultID) {
                            let index = cdNotesRecordIDs.index(of: resultID)
                            cdNotesRecordIDs.remove(at: index!)
                            cdNotesRecords.remove(at: index!)
                        }
                    }
                }
                
                // sync remaining records to cloudkit
                for note in cdNotesRecords {
                    let ckNote = CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: note.id!, zoneID: zoneID))
                        
                    let reference = CKReference(recordID: CKRecordID(recordName: associatedWith.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
                    ckNote.setObject(reference, forKey: "associatedRecord")
                    ckNote.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
                    ckNote.setObject(note.title! as CKRecordValue?, forKey: "title")
                    ckNote.setObject(note.noteString! as CKRecordValue?, forKey: "noteString")
                    
                    privateDatabase.save(ckNote, completionHandler: { (record, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                    })
                }
            }
        })
    }
    
    static func importAssociatedImages(cdRecord: Record, syncedDate: Date, context: NSManagedObjectContext) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let associatedImages = CoreDataHelper.fetchImages(for: cdRecord, in: context) //loadAssociatedCDImages(for: cdRecord)
        
        for image in associatedImages {
            let ckImage = CKRecord(recordType: "Images", recordID: CKRecordID(recordName: image.id!, zoneID: zoneID))
            
            let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
            let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
            do {
                try image.image!.write(to: url, options: NSData.WritingOptions.atomicWrite)
                
                let imageAsset = CKAsset(fileURL: url)
                
                ckImage.setObject(imageAsset, forKey: "image")
                
                let reference = CKReference(recordID: CKRecordID(recordName: cdRecord.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
                ckImage.setObject(reference, forKey: "associatedRecord")
                ckImage.setObject(syncedDate as CKRecordValue?, forKey: "lastSynced")
                ckImage.setObject(image.id as CKRecordValue?, forKey: "id")
                ckImage.setObject(0 as CKRecordValue?, forKey: "recentlyDeleted")
                
                privateDatabase.save(ckImage, completionHandler: { (record, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    DispatchQueue.main.async {
                        print("Successfully saved image to cloudkit")
                    }
                })
            } catch {
                DispatchQueue.main.async {
                    print("Problems writing image data to URL")
                }
            }
        }
    }
    
    static func importAssociatedNotes(cdRecord: Record, syncedDate: Date, context: NSManagedObjectContext) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let associatedNotes = CoreDataHelper.fetchNotes(for: cdRecord, in: context)
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        
        for note in associatedNotes {
            let ckNote = CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: note.id!, zoneID: zoneID))
            
            let reference = CKReference(recordID: CKRecordID(recordName: cdRecord.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
            ckNote.setObject(reference, forKey: "associatedRecord")
            ckNote.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
            ckNote.setObject(note.title! as CKRecordValue, forKey: "title")
            ckNote.setObject(note.noteString! as CKRecordValue, forKey: "noteString")
            ckNote.setObject(0 as CKRecordValue?, forKey: "recentlyDeleted")
            
            privateDatabase.save(ckNote, completionHandler: { (record, error) in
                if error != nil {
                    print(error!)
                    return
                }
                DispatchQueue.main.async {
                    print("Successfully saved note to cloudkit")
                }
            })
        }
    }
    
    static func saveImageToCloud(imageRecord: Image, associatedRecord: Record) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        
        let ckImage = CKRecord(recordType: "Images", recordID: CKRecordID(recordName: imageRecord.id!, zoneID: zoneID))
        
        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
        let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        do {
            try imageRecord.image!.write(to: url, options: NSData.WritingOptions.atomicWrite)
            
            let imageAsset = CKAsset(fileURL: url)
            
            ckImage.setObject(imageAsset, forKey: "image")
            
            let reference = CKReference(recordID: CKRecordID(recordName: associatedRecord.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
            ckImage.setObject(reference, forKey: "associatedRecord")
            ckImage.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
            ckImage.setObject(imageRecord.id as CKRecordValue?, forKey: "id")
            ckImage.setObject(0 as CKRecordValue, forKey: "recentlyDeleted")
            
            privateDatabase.save(ckImage, completionHandler: { (record, error) in
                if error != nil {
                    print(error!)
                    return
                }
                DispatchQueue.main.async {
                    print("Successfully saved image to cloudkit")
                }
            })
        } catch {
            DispatchQueue.main.async {
                print("Problems writing image data to URL")
            }
        }
    }
    
    static func saveNoteToCloud(noteRecord: Note, associatedRecord: Record) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        
        let recordID = CKRecordID(recordName: noteRecord.id!, zoneID: zoneID)
        
        privateDatabase.fetch(withRecordID: recordID, completionHandler: ({record, error in
            if let err = error {
                DispatchQueue.main.async() {
                    print(err.localizedDescription)
                    print("Couldn't find record, create new note.")
                }
                let ckNote = CKRecord(recordType: "Notes", recordID: CKRecordID(recordName: recordID.recordName, zoneID: zoneID))
                
                do {
                    let reference = CKReference(recordID: CKRecordID(recordName: associatedRecord.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
                    ckNote.setObject(reference, forKey: "associatedRecord")
                    ckNote.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
                    ckNote.setObject(noteRecord.title! as CKRecordValue, forKey: "title")
                    ckNote.setObject(noteRecord.noteString! as CKRecordValue, forKey: "noteString")
                    ckNote.setObject(0 as CKRecordValue, forKey: "recentlyDeleted")
                    
                    privateDatabase.save(ckNote, completionHandler: { (record, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        DispatchQueue.main.async {
                            print("Successfully saved note to cloudkit")
                        }
                    })
                }
            } else {
                // found record, update it
                do {
                    let reference = CKReference(recordID: CKRecordID(recordName: associatedRecord.recordID!, zoneID: zoneID) , action: CKReferenceAction.deleteSelf)
                    record?.setObject(reference, forKey: "associatedRecord")
                    record?.setObject(Date() as CKRecordValue?, forKey: "lastSynced")
                    record?.setObject(noteRecord.title! as CKRecordValue, forKey: "title")
                    record?.setObject(noteRecord.noteString! as CKRecordValue, forKey: "noteString")
                    
                    privateDatabase.save(record!, completionHandler: { (savedRecord, error) in
                        if error != nil {
                            print(error!)
                            return
                        }
                        DispatchQueue.main.async {
                            print("Successfully updated note in cloudkit")
                        }
                    })
                }
            }
        }))
    }
    
    // Can be used to delete notes or images from a record.
    static func deleteWithID(recordID: String) {
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        let ckRecordID = CKRecordID(recordName: recordID, zoneID: zoneID)
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        privateDatabase.fetch(withRecordID: ckRecordID, completionHandler: ({record, error in
            if let err = error {
                DispatchQueue.main.async() {
                    print(err.localizedDescription)
                }
            } else {
                // found record
                record?.setObject(1 as CKRecordValue, forKey: "recentlyDeleted")
                record?.setObject(Date() as CKRecordValue, forKey: "lastSynced")
                
                privateDatabase.save(record!, completionHandler: { (savedRecord, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    DispatchQueue.main.async {
                        print("Successfully updated item in cloudkit")
                    }
                })
            }
        }))
    }
    
    static func permanentlyDeleteWithID(recordID: String) {
        let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
        let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
        privateDatabase.delete(withRecordID: CKRecordID(recordName: recordID, zoneID: zoneID), completionHandler: ({record, error in
            if let err = error {
                DispatchQueue.main.async() {
                    print(err.localizedDescription)
                }
            }
        }))
    }
}
