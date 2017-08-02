//
//  ImageViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-11-25.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var image: UIImage!
    var imageIndex: Int!
    var isEditingRecord: Bool!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!
    
    weak var deleteImageDelegate: EditImageDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        // remove delete button
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
        
        deleteButton.isEnabled = false
        if isEditingRecord{
            // show delete button
            deleteButton.tintColor = .red
            deleteButton.isEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let shareText = "Shared from UnderWarranty."
        
        if let image = image {
            let vc = UIActivityViewController(activityItems: [shareText, image], applicationActivities: [])
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        // delete image and pop view controller
        deleteImageDelegate?.removeImage(at: imageIndex)
        _ = navigationController?.popViewController(animated: true)
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        // only show option to delete if currently editing record.
        if isEditingRecord! {
            if imageIndex != 0 && imageIndex != 1 {
                let delete = UIPreviewAction(title: "Delete", style: .destructive, handler: {_,_ in
                    self.deleteImageDelegate?.removeImage(at: self.imageIndex)
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
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
