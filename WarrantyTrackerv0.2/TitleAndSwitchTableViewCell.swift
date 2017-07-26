//
//  TitleAndSwitchTableViewCell.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2017-04-12.
//  Copyright © 2017 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class TitleAndSwitchTableViewCell: UITableViewCell {
    
    @IBOutlet var toggle: UISwitch!
    
    @IBAction func toggleSwitch(_: Any) {
        defaults.set(toggle.isOn, forKey: "SyncUsingData")
    }
}
