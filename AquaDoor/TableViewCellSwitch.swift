//
//  UITableViewCellSwitch.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/10/17.
//  Copyright © 2017 Ben Faingold. All rights reserved.
//

import UIKit

class TableViewCellSwitch: UITableViewCell {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		accessoryView = UISwitch()
	}
}
