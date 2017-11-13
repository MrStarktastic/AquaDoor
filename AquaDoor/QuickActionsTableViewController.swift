//
//  QuickActionsTableViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/11/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

class QuickActionsTableViewController: UITableViewController {
	let ASSIGNED_SECTION_INDEX = 0, UNASSIGNED_SECTION_INDEX = 1
	let MAX_ASSIGNED_COUNT = 3
	private var sections: [[String]]!

	override func viewDidLoad() {
		super.viewDidLoad()
		sections = [["Door 1", "Door 2", "Door 3"], ["Door 4", "Door 5", "Door 6"]]
		tableView.isEditing = true
	}

	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
	                        to destinationIndexPath: IndexPath) {
		let sourceSectionIndex = sourceIndexPath.section
		let destinationSectionIndex = destinationIndexPath.section
		sections.moveElement(fromArrayAt: sourceSectionIndex, atCell: sourceIndexPath.row,
		                     toArrayAt: destinationSectionIndex, atCell: destinationIndexPath.row)

		if sourceSectionIndex == ASSIGNED_SECTION_INDEX ||
			destinationSectionIndex == ASSIGNED_SECTION_INDEX {
			// Assigned section was modified, apply changes to Quick Actions
		}
	}

	override func tableView(_ tableView: UITableView,
	                        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
	                        toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		if sourceIndexPath.section == UNASSIGNED_SECTION_INDEX &&
			proposedDestinationIndexPath.section == ASSIGNED_SECTION_INDEX &&
			sections[ASSIGNED_SECTION_INDEX].count == MAX_ASSIGNED_COUNT {
			return sourceIndexPath
		}

		return proposedDestinationIndexPath
	}

	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return .none
	}

	override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
}
