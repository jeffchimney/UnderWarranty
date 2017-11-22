//
//  UserDefaultsHelper.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-04-12.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation

let defaults = UserDefaults.standard

class UserDefaultsHelper {
    
    static func getUsername() -> String {
        return defaults.object(forKey: "username") as! String
    }
    
    static func getPassword() -> String {
        return defaults.object(forKey: "password") as! String
    }
    
    static func isSignedIn() -> Bool {
        if (defaults.object(forKey: "SignedIn") as? Bool) != nil {
            return defaults.object(forKey: "SignedIn") as! Bool
        } else {
            return false
        }
    }
    
    static func isSignedIn(bool: Bool) {
        defaults.set(bool, forKey: "SignedIn")
    }
    
    static func deleteAfterDays() {
        
    }
    
    static func deleteAfter(days: Int) {
        
    }
    
    static func canSyncUsingData() -> Bool {
        return defaults.object(forKey: "SyncUsingData") as! Bool
    }
    
    static func hasCameraPermissions() -> Bool {
        return defaults.object(forKey: "CameraPermissions") as! Bool
    }
    
    static func hasCalendarPermissions() -> Bool {
        return defaults.object(forKey: "CalendarPermissions") as? Bool ?? false
    }
    
    static func currentConnection() -> String {
        return defaults.object(forKey: "connection") as! String
    }
    
    static func getQueuedChanges() -> [String]? {
        return  defaults.object(forKey: "recordQueue") as? [String]
    }
    
    static func getQueuedToDelete() -> [String]? {
        return  defaults.object(forKey: "toDeleteQueue") as? [String]
    }
    
    static func syncEnabled() -> Bool {
        return  defaults.object(forKey: "CanSync") as! Bool
    }
    
    static func addRecordToQueue(recordID: String) {
        if UserDefaultsHelper.syncEnabled() {
            var queuedRecords = defaults.object(forKey: "recordQueue") as! [String]?
            
            if queuedRecords != nil {
                if !(queuedRecords?.contains(recordID))! {
                    queuedRecords!.append(recordID)
                }
            } else {
                queuedRecords = []
                queuedRecords!.append(recordID)
            }
            defaults.set(queuedRecords, forKey: "recordQueue")
        }
    }
    
    static func addRecordToDeleteQueue(recordID: String) {
        if UserDefaultsHelper.syncEnabled() {
            var queuedRecords = defaults.object(forKey: "recordQueue") as! [String]?
            
            if queuedRecords != nil {
                if !(queuedRecords?.contains(recordID))! {
                    queuedRecords!.append(recordID)
                }
            } else {
                queuedRecords = []
                queuedRecords!.append(recordID)
            }
            defaults.set(queuedRecords, forKey: "toDeleteQueue")
        }
    }
    
    static func setQueueToEmpty() {
        defaults.set([], forKey: "recordQueue")
    }
    
    static func setCanSyncUsingData(to: Bool) {
        defaults.set(to, forKey: "SyncUsingData")
    }
    
    static func setSyncEnabled(to: Bool) {
        defaults.set(to, forKey: "CanSync")
    }
    
    static func setToDeleteQueueToEmpty() {
        defaults.set([], forKey: "toDeleteQueue")
    }
    
    static func setCameraPermissions(to: Bool) {
        defaults.set(to, forKey: "CameraPermissions")
    }
    
    static func setCalendarPermissions(to: Bool) {
        defaults.set(to, forKey: "CalendarPermissions")
    }
}
