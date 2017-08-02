//
//  WarrantyTableViewCellController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-11-05.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import Foundation
import UIKit

class WarrantyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var warrantyStarts: UILabel!
    @IBOutlet weak var warrantyEnds: UILabel!
    @IBOutlet weak var warrantyImageView: UIImageView!
    @IBOutlet weak var dashLabel: UILabel!
    @IBOutlet weak var photoLoadingIndicator: UIActivityIndicatorView!
}
