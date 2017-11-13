//
//  CredentialAlertControllerWrapper.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/9/17.
//  Copyright © 2017 Ben Faingold. All rights reserved.
//

import UIKit

class CredentialAlertControllerWrapper {
	public private(set) var controller: UIAlertController

	private var confirmAction: UIAlertAction!

	private var nonEmptyTextFields: [String: Bool]

	private var delegate: CredentialAlertDelegate!

	init(title: String?, message: String?, delegate: CredentialAlertDelegate, cancellable: Bool) {
		controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
		self.delegate = delegate

		// If cancellable, then text fields are necessarily non empty
		nonEmptyTextFields = ["username": cancellable, "password": cancellable]

		let selector = #selector(textFieldDidChange)
		controller.addTextField { textField in
			textField.placeholder = "username"
			textField.addTarget(self, action: selector, for: .editingChanged)
			textField.becomeFirstResponder()
		}
		controller.addTextField { textField in
			textField.placeholder = "password"
			textField.addTarget(self, action: selector, for: .editingChanged)
			textField.isSecureTextEntry = true
		}

		confirmAction = UIAlertAction(title: "Enter", style: .default, handler: didTapConfirm)
		confirmAction.isEnabled = false
		controller.addAction(confirmAction)

		if cancellable { controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil)) }
	}

	private func didTapConfirm(_: UIAlertAction) {
		let textFields = controller.textFields!
		let username = textFields[0].text!
		let password = textFields[1].text!
		delegate.didSetCredentials(username: username, password: password)
		CredentialManager.save(username: username, password: password)
	}

	@objc private func textFieldDidChange(_ textField: UITextField){
		nonEmptyTextFields[textField.placeholder!] = !textField.text!.trimWhitespaces().isEmpty
		confirmAction!.isEnabled = !nonEmptyTextFields.values.contains(false)
	}
}

protocol CredentialAlertDelegate {
	func didSetCredentials(username: String, password: String)
}
