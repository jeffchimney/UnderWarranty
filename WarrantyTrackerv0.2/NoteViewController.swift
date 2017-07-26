//
//  NoteViewController.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-01-24.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData

class NoteViewController: UIViewController, UITextFieldDelegate {
    
    // variables passed from last view
    var record: Record!
    var isEditingRecord: Bool!
    var selectedNotesIndex: Int!
    var note: Note!
    //
    
    @IBOutlet weak var noteTitle: UITextField!
    @IBOutlet weak var noteBody: UITextView!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    weak var handleNotesDelegate: HandleNotesDelegate?
    
    override func viewDidLoad() {
        noteTitle.placeholder = "Title"
        noteTitle.borderStyle = .none
        noteTitle.text = note.title!
        noteBody.text = note.noteString!
        navigationController?.setToolbarHidden(false, animated: false)
        
        if !isEditingRecord {
            deleteButton.isEnabled = false
        }
        
        // fonts
        let defaultFont = UIFont(name: "Kohinoor Bangla", size: 17)!
        let attributes = [
            NSFontAttributeName: defaultFont
        ]
        
        noteTitle.defaultTextAttributes = attributes
        noteBody.font = UIFont(name: "Kohinoor Bangla", size: 15)!
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        noteTitle.resignFirstResponder()
        noteBody.resignFirstResponder()
        saveNoteLocally()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        noteTitle.resignFirstResponder()
        noteBody.becomeFirstResponder()
        return false
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        handleNotesDelegate?.deleteNote(at: selectedNotesIndex)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func saveNoteLocally() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        if selectedNotesIndex == 0 {
            record.descriptionString = noteBody.text
            
            do {
                try managedContext.save()
                print("Updated note in CoreData")
                
                // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.updateRecordInCloudKit(cdRecord: record, context: managedContext)
                } else {
                    // queue up the record to sync when you have a good connection
                    UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                }
            } catch {
                print("Problems updating note to CoreData")
            }
            handleNotesDelegate?.passBack(newNote: note, selectedIndex: selectedNotesIndex)
        } else {
            if self.note.id != "temp" {
                let returnedNote = CoreDataHelper.fetchNote(with: self.note.id!, in: managedContext)
                
                if returnedNote != nil {
                    returnedNote?.title = noteTitle.text
                    returnedNote?.noteString = noteBody.text
                    returnedNote?.record = record!
                    
                    do {
                        try managedContext.save()
                        print("Updated note in CoreData")
                        
                        // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                        let conn = UserDefaultsHelper.currentConnection()
                        if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                            CloudKitHelper.saveNoteToCloud(noteRecord: returnedNote!, associatedRecord: record!)
                        } else {
                            // queue up the record to sync when you have a good connection
                            UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                        }
                    } catch {
                        print("Problems updating note to CoreData")
                    }
                    handleNotesDelegate?.passBack(newNote: note, selectedIndex: selectedNotesIndex)
                }
            } else {
                note.title = noteTitle.text
                note.noteString = noteBody.text
                note.record = record!
                note.id = UUID().uuidString
                
                do {
                    try managedContext.save()
                    print("Saved note to CoreData")
                    
                    // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
                    let conn = UserDefaultsHelper.currentConnection()
                    if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                        CloudKitHelper.saveNoteToCloud(noteRecord: note, associatedRecord: record!)
                    } else {
                        // queue up the record to sync when you have a good connection
                        UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
                    }
                } catch {
                    print("Problems saving note to CoreData")
                }
                handleNotesDelegate?.passBack(newNote: note, selectedIndex: selectedNotesIndex)
            }
        }
        
        performSegue(withIdentifier: "unwindFromCreateNote", sender: self)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        // only show option to delete if currently editing record.
        if isEditingRecord! {
            if selectedNotesIndex != 0 {
                let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
                    self.handleNotesDelegate?.deleteNote(at: self.selectedNotesIndex)
                })
                
                let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
                    print("Cancel Action Selected")
                }
                
                return [delete, cancel]
            } else {
                return []
            }
        } else {
            return []
        }
    }
}
