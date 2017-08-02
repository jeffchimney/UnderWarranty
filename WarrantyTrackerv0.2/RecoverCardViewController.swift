//
//  RecoverCardViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-01-09.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class RecoverCardViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var record: Record!
    var recoverRecordDelegate: ReloadDeletedTableViewDelegate?
    var managedContext: NSManagedObjectContext?
    
    override func viewDidLoad() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchedImages = CoreDataHelper.fetchImages(for: record, in: managedContext!)
        
        if fetchedImages.count > 0 {
            let recordImage = fetchedImages[0]
            imageView.image = UIImage(data: recordImage.image! as Data)
        } else {
            imageView.image = UIImage(named: "placeholder")
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
            
            CoreDataHelper.delete(record: self.record, in: self.managedContext!) //self.deleteFromCoreData(record: self.record)
            self.recoverRecordDelegate?.reloadLastControllerTableView()
        })
        
        let recover = UIPreviewAction(title: "Recover", style: .default, handler: {_,_ in
            CoreDataHelper.setRecentlyDeletedFalse(for: self.record, in: self.managedContext!) //self.setRecentlyDeletedFalse(for: self.record)
            self.recoverRecordDelegate?.reloadLastControllerTableView()
        })
        
        let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, controller) in
            print("Cancel Action Selected")
        }
        
        return [delete, recover, cancel]
    }
}
