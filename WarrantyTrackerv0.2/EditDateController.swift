//
//  EditDateController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-12-12.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class EditDateController: UIViewController {
    
    var pickedDate: Date!
    var tappedStartDate: Bool!
    @IBOutlet weak var datePicker: UIDatePicker!
    weak var delegate: DataBackDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datePicker.datePickerMode = UIDatePickerMode.date
        datePicker.date = pickedDate
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // send data back to previous controller
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        self.delegate?.savePreferences(labelText: dateFormatter.string(from: datePicker.date), changeStartDate: tappedStartDate)
    }
}
