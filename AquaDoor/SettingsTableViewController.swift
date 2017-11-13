//
//  SettingsTableViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/9/17.
//  Copyright © 2017 Ben Faingold. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController, CredentialAlertDelegate {
	@IBOutlet weak var developerModeCell: TableViewCellSwitch!

	override func viewDidLoad() {
		super.viewDidLoad()

		/// Disables weird selection behavior when interacting with this cell.
		developerModeCell.selectionStyle = .none

		let uiSwitch = developerModeCell.accessoryView as! UISwitch
		uiSwitch.setOn(UserDefaults.standard.bool(forKey: "developerMode"), animated: false)
		uiSwitch.addTarget(self, action: #selector(didDeveloperModeSwitchChange), for: .valueChanged)
	}

	@objc func didDeveloperModeSwitchChange(_ uiSwitch: UISwitch) {
		UserDefaults.standard.set(uiSwitch.isOn, forKey: "developerMode")
	}

	@IBAction func didTapEditCredentials() {
		let (oldUsername, oldPassword) = SSHCommander.credentials!

		let dialog = CredentialAlertControllerWrapper(title: "Edit Credentials", message: nil,
		                                              delegate: self, cancellable: true).controller
		let textFields = dialog.textFields!
		textFields[0].text = oldUsername
		textFields[1].text = oldPassword

		present(dialog, animated: true, completion: nil)
	}

	func didSetCredentials(username: String, password: String) {
		SSHCommander.credentials = (username, password)
	}

	@IBAction func didTapDone(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
}
