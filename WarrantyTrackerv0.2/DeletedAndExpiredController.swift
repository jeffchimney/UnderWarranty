//
//  DeletedAndExpiredController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-12-21.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData

public protocol ReloadDeletedTableViewDelegate: class {
    func reloadLastControllerTableView()
}

class DeletedAndExpiredController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate, ReloadDeletedTableViewDelegate {
    
    let cellIdentifier = "WarrantyTableViewCell"
    var fetchedRecords: [Record] = []
    var expiredRecords: [Record] = []
    var deletedRecords: [Record] = []
    var sections: [[Record]] = [[]]
    var managedContext: NSManagedObjectContext?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.reloadData()
        
        // register for previewing with 3d touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            print("3D Touch Not Available")
        }
        
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        sortRecordsToSections()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Expired"
        } else {
            return "Recently Deleted"
        }
    }
    
    func sortRecordsToSections() {
        fetchedRecords = CoreDataHelper.fetchAllRecords(in: managedContext!)
        
        //get your object from CoreData
        for eachRecord in fetchedRecords {
            if eachRecord.recentlyDeleted {
                deletedRecords.append(eachRecord)
            } else if eachRecord.expired {
                expiredRecords.append(eachRecord)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! WarrantyTableViewCell
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        if indexPath.section == 0 {
            if expiredRecords.count == 0 {
                cell.title.text = "None found."
                cell.warrantyStarts.isHidden = true
                cell.warrantyEnds.isHidden = true
                cell.warrantyImageView.isHidden = true
                cell.dashLabel.isHidden = true
                cell.isUserInteractionEnabled = false
            } else {
                expiredRecords.sort(by:{ $0.warrantyEnds?.compare($1.warrantyEnds! as Date) == .orderedDescending})
                let record = expiredRecords[indexPath.row]
                cell.title.text = record.title
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
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                }
            }
        } else {
            if deletedRecords.count == 0 {
                cell.title.text = "None found."
                cell.warrantyStarts.isHidden = true
                cell.warrantyEnds.isHidden = true
                cell.warrantyImageView.isHidden = true
                cell.dashLabel.isHidden = true
                cell.isUserInteractionEnabled = false
            }else {
                deletedRecords.sort(by:{ $0.dateDeleted?.compare($1.dateDeleted! as Date) == .orderedDescending})
                let record = deletedRecords[indexPath.row]
                cell.title.text = record.title
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
                } else {
                    cell.warrantyImageView.image = UIImage(named: "placeholder")
                }
            }
        }
        
        cell.warrantyImageView.contentMode = .scaleAspectFit
        cell.title.textColor = cell.tintColor
        cell.backgroundColor = UIColor(colorLiteralRed: 189, green: 195, blue: 201, alpha: 1.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if expiredRecords.count == 0 {
                return 1
            } else {
                return expiredRecords.count
            }
        } else {
            if deletedRecords.count == 0 {
                return 1
            } else {
                return deletedRecords.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        // recover record on press recover
        let recover = UITableViewRowAction(style: .normal, title: "Recover") { action, index in
            if indexPath.section == 1 { // recently deleted
                CoreDataHelper.setRecentlyDeletedFalse(for: self.deletedRecords[indexPath.row], in: self.managedContext!)
                self.deletedRecords.remove(at: self.deletedRecords.index(of: self.deletedRecords[indexPath.row])!)
                tableView.reloadData()
            }
        }
        recover.backgroundColor = tableView.tintColor
        
        // delete record on press delete
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            if indexPath.section == 0 { // expired
                
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.permanentlyDeleteWithID(recordID: self.expiredRecords[indexPath.row].recordID!)
                } else {
                    UserDefaultsHelper.addRecordToDeleteQueue(recordID: self.expiredRecords[indexPath.row].recordID!)
                }
                CoreDataHelper.delete(record: self.expiredRecords[indexPath.row], in: self.managedContext!)
                self.expiredRecords.remove(at: indexPath.row)
            } else { // recently deleted
                let conn = UserDefaultsHelper.currentConnection()
                if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
                    CloudKitHelper.permanentlyDeleteWithID(recordID: self.deletedRecords[indexPath.row].recordID!)
                } else {
                    UserDefaultsHelper.addRecordToDeleteQueue(recordID: self.deletedRecords[indexPath.row].recordID!)
                }
                CoreDataHelper.delete(record: self.deletedRecords[indexPath.row], in: self.managedContext!)
                self.deletedRecords.remove(at: indexPath.row)
            }
            tableView.reloadData()
        }
        delete.backgroundColor = .red
        
        if indexPath.section == 1 {
            return [delete, recover]
        } else {
            return [delete]
        }
    }
    
    func reloadLastControllerTableView() {
        deletedRecords = []
        expiredRecords = []
        sortRecordsToSections()
        tableView.reloadData()
    }
    
    //MARK: Peek and Pop methods
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        // convert point from position in self.view to position in warrantiesTableView
        let cellPosition = tableView.convert(location, from: self.view)
        
        guard let indexPath = tableView.indexPathForRow(at: cellPosition),
            let cell = tableView.cellForRow(at: indexPath) else {
                return nil
        }
        
        guard let recoverViewController =
            storyboard?.instantiateViewController(
                withIdentifier: "recoverCardViewController") as?
            RecoverCardViewController else {
                return nil
        }
        
        let selectedRecord = deletedRecords[indexPath.row]
        
        recoverViewController.recoverRecordDelegate = self
        recoverViewController.record = selectedRecord
            recoverViewController.preferredContentSize =
            CGSize(width: 0.0, height: 500)
        
        previewingContext.sourceRect = view.convert(cell.frame, from: tableView)
        
        return recoverViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //show(viewControllerToCommit, sender: self)
    }
}

