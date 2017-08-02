//
//  AddTableViewCell.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2017-01-16.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class AddTableViewCell: UITableViewCell {
    
    var isAdding = false
    var originalButtonCenter: CGPoint!
    
    @IBOutlet weak var addCellButton: UIButton!
    @IBOutlet weak var hiddenAddButton: UIButton!
    var textButton = UIButton()
    var imageButton = UIButton()
    
    weak var addNotesDelegate: AddNotesCellDelegate?
    
    @IBAction func addButtonPushed(_ sender: Any) {
        self.addNotesDelegate?.addNotesButtonPressed()
//        if isAdding {
//            isAdding = false
////            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: [], animations: {
////                self.addCellButton.tintColor = self.tintColor
////                self.addCellButton.center = self.originalButtonCenter
////                self.textButton.center = CGPoint(x: -self.imageButton.frame.width, y: self.frame.height/2)
////                self.imageButton.center = CGPoint(x: -self.textButton.frame.width, y: self.frame.height/2)
////                self.addCellButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
////            }, completion: nil)
//        } else {
//            // set up buttons that will come in from the left
//            hiddenAddButton.isHidden = true
//            
////            textButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
////            textButton.layer.cornerRadius = 20
////            textButton.setTitle("T", for: .normal)
////            textButton.backgroundColor = self.tintColor
////            textButton.center = CGPoint(x: -20, y: self.frame.height/2)
////            
////            imageButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
////            imageButton.layer.cornerRadius = 20
////            imageButton.setTitle("I", for: .normal)
////            imageButton.setTitleColor(.white, for: .normal)
////            imageButton.backgroundColor = self.tintColor
////            imageButton.center = CGPoint(x: -20, y: self.frame.height/2)
//            
//           // self.addSubview(textButton)
//            //self.addSubview(imageButton)
//            
//            originalButtonCenter = addCellButton.center
//            isAdding = true
//            
////            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: [], animations: {
////                self.addCellButton.tintColor = UIColor.red
////                self.addCellButton.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_4))
////                self.addCellButton.center = self.hiddenAddButton.center
////                self.imageButton.center = CGPoint(x: self.imageButton.frame.width * 2, y: self.frame.height/2)
////                self.textButton.center = CGPoint(x: self.imageButton.frame.width * 0.75, y: self.frame.height/2)
////            }, completion: nil)
//        }
    }
}
