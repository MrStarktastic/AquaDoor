//
//  ActionViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/29/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit
import UITextField_Shake

class ActionViewController: UIViewController, UITextFieldDelegate, ProgressButtonDelegate, LeaveDoorOpenDelegate {
	fileprivate let animationDuration = 0.3
	fileprivate let flexibleAutoresizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

	@IBOutlet weak var doorIdTextField: UITextField!
	@IBOutlet weak var addToFavoritesButton: BorderedRectButton!
	@IBOutlet weak var statusButton: UIButton!
	@IBOutlet var progressButtons: [RoundProgressButton]!
	@IBOutlet weak var actionArea: UIView!
	@IBOutlet var voidViews: [UIView]!

	private var durationPickerOverlay: DurationPickerOverlay!

	/// True while there is no task in progress.
	private var isIdle = true

	/// True when this VC is about to be dismissed.
	private var isFinishing = false

	private var database: Database = .shared

	private var doorId: String { get { return doorIdTextField.text!.trimWhitespaces().uppercased() }}

	private var delegate: DoorActionDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()

		setupBackground()
		setupVoidViews()
		addKeyboardObservers()
		progressButtons.forEach { $0.delegate = self }

		durationPickerOverlay = DurationPickerOverlay(within: view.frame, autoresizingMask: flexibleAutoresizingMask)
		durationPickerOverlay.addCancelRecognizers(target: self, selector: #selector(dismissDurationPicker))
		durationPickerOverlay.addDoneAction(selector: #selector(setDurationFromPicker))

		doorIdTextField.attributedPlaceholder = NSAttributedString(
			string: doorIdTextField.placeholder!,
			attributes: [.foregroundColor: { let v: CGFloat = 140 / 255
				return UIColor(red: v, green: v, blue: v, alpha: 1) }()])
		doorIdTextField.delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.alpha = 0
		UIView.animate(withDuration: animationDuration) { self.view.alpha = 1 }

		doorIdTextField.becomeFirstResponder()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		delegate.doorActionViewControllerWillDisappear()
	}

	override func didMove(toParentViewController parent: UIViewController?) {
		delegate = parent as? DoorActionDelegate
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		return isIdle && finish()
	}

	func progressAnimationDidStop(_ sender: RoundProgressButton) {
		toggleEnabilityOfViews(to: true, exceptFor: sender)
	}

	private func addKeyboardObservers() {
		let notifCenter = NotificationCenter.default
		notifCenter.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
		notifCenter.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
	}

	/// Sets dimmed background and blur for action area.
	private func setupBackground() {
		view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)

		let actionAreaBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		actionAreaBlur.frame = actionArea.bounds
		actionAreaBlur.autoresizingMask = flexibleAutoresizingMask
		actionAreaBlur.layer.cornerRadius = 10
		actionAreaBlur.clipsToBounds = true
		actionArea.insertSubview(actionAreaBlur, at: 0)
	}

	// UIViews surrounding the interactive area can be used for dismissal of DoorActionView
	private func setupVoidViews() {
		let selector = #selector(finish)

		for voidView in voidViews {
			let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: selector)
			swipeDownRecognizer.direction = .down
			voidView.addGestureRecognizer(swipeDownRecognizer)
			voidView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: selector))
		}
	}

	// All destructive views are disabled except for the button that led to this,
	// also the text field doesn't get disabled because it's not really destructive
	// and we don't want the keyboard to toggle at all.
	private func toggleEnabilityOfViews(to enabled: Bool, exceptFor buttonToExclude: UIButton) {
		isIdle = enabled
		addToFavoritesButton.isUserInteractionEnabled = enabled
		statusButton.isUserInteractionEnabled = enabled
		voidViews.isUserInteractionEnabled = enabled

		for button in progressButtons where button != buttonToExclude {
			button.isUserInteractionEnabled = enabled
		}
	}

	/// Presents an error that has occured during the execution of a DoorTask,
	/// hence causing its termination.
	///
	/// - Parameters:
	///   - result: Describes the result of the task. This function is only concerned
	///		with failure related results, i.e. doorIdNotFound & SSHError.
	///   - doorId: The door identifier on which the task was performed.
	private func presentActionError(_ result: DoorTask.Result, _ doorId: String) {
		switch result {
		case .doorIdNotFound:
			presentAlertController(withTitle: "Door with ID \(doorId) Was Not Found", andMessage: nil)
		case .error(let sshError):
			analyzeSSHError(sshError)
		default: // Only needed for this switch to be exhaustive
			return
		}
	}

	private func analyzeSSHError(_ error: SSHError) {
		switch error {
		case .connectionFailed:
			presentAlertController(withTitle: "Error", andMessage: "Make sure that WiFi is turned on and that you're connected to a network with access to the public servers (e.g. eduroam).")
		case .executionFailed:
			presentAlertController(withTitle: "Error", andMessage: "Something went wrong while executing the command.")
		default: // Error is credential-related
			delegate.credentialErrorDidOccur(error)
		}
	}

	@IBAction func didTapDoorActionButton(_ sender: UIButton) {
		let doorId = self.doorId

		if doorId.isEmpty {
			doorIdTextField.shake()
			return
		}

		let task = DoorTask(delegate: self)
		let kind = DoorTask.Kind(rawValue: sender.tag)!

		// .status task kind has start & completion blocks different than other types
		if kind == .status {
			task.execute(kind: kind, onDoorWithId: doorId, start: presentActivityIndicator) { result in
				if case .status(let s) = result { // s should be either "opened" or "closed"
					self.removeActivityIndicator()
					self.presentDoorStatus(doorId, s)
					return
				}

				self.presentActionError(result, doorId)
			}

			return
		}

		// kind is .close, .open or .leaveOpen
		let sender = sender as! RoundProgressButton

		task.execute(kind: kind, onDoorWithId: doorId, start: {
			self.toggleEnabilityOfViews(to: false, exceptFor: sender)
			sender.animateProgress()
		}) { result in
			if case .status(_) = result {
				sender.stopProgressAnimation(success: true)
				return
			}

			sender.stopProgressAnimation(success: false)
			self.presentActionError(result, doorId)
		}
	}

	@IBAction func didTapAddButton() {
		let doorId = self.doorId

		if !doorId.isEmpty {
			if try! database.add(doorWithId: doorId) {
				delegate.didAddToFavorites(doorId: doorId)
			} else {
				presentAlertController(withTitle: "Error Adding Door to Favorites",
				                       andMessage: "Door with ID \(doorId) has already been added to favorites.")
			}
		} else {
			doorIdTextField.shake()
		}
	}

	func needsDurationToLeaveDoorOpen(_ pendingTask: DoorTask.PendingLeaveOpen) {
		if !DoorUtil.isCorridorOrTraklin(pendingTask.doorId) {
			presentAlertController(withTitle: "Door Cannot Be Left Open",
				andMessage: "Only doors that belong to corridors or traklins can be opened for longer than the default.")
			return
		}

		durationPickerOverlay.pendingTask = pendingTask

		let background = durationPickerOverlay.backgroundView
		background.alpha = 0
		view.addSubview(background)
		UIView.animate(withDuration: animationDuration) { background.alpha = 0.75 }

		doorIdTextField.inputAccessoryView = durationPickerOverlay.toolbar
		doorIdTextField.inputView = durationPickerOverlay.picker
		doorIdTextField.reloadInputViews()
	}

	@objc private func dismissDurationPicker() {
		let backgroundView = durationPickerOverlay.backgroundView

		UIView.animate(withDuration: animationDuration, animations: { backgroundView.alpha = 0 })
		{ _ in backgroundView.removeFromSuperview() }

		doorIdTextField.inputAccessoryView = nil
		doorIdTextField.inputView = nil
		doorIdTextField.reloadInputViews()
	}

	@objc private func setDurationFromPicker() {
		dismissDurationPicker()
		durationPickerOverlay.pendingTask.leaveOpen(for: Int(durationPickerOverlay.picker.countDownDuration / 60))
	}

	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height,
			keyboardHeight != 0 && keyboardHeight != -actionArea.transform.ty {
			let translationY = CGAffineTransform(translationX: 0, y: -keyboardHeight)
			self.actionArea.transform = translationY
			self.voidViews.forEach { $0.transform = translationY }
		}
	}

	@objc func keyboardWillHide(notification: NSNotification) {
		if isFinishing {
			actionArea.transform = .identity
			voidViews.forEach { $0.transform = .identity }
		}
	}

	@objc func finish() -> Bool {
		isFinishing = true
		doorIdTextField.resignFirstResponder()

		UIView.animate(withDuration: animationDuration, animations: { self.view.alpha = 0 })
		{ _ in
			NotificationCenter.default.removeObserver(self)
			self.view.removeFromSuperview()
			self.removeFromParentViewController()
		}

		return true
	}

	private func presentAlertController(withTitle title: String?, andMessage message: String?) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}

	private func presentActivityIndicator() {
		view.endEditing(true)
		
		let controller = ActivityIndicatorViewController(text: "Fetching status...")
		addChildViewController(controller)
		view.addSubview(controller.view)
		controller.didMove(toParentViewController: self)
	}

	private func removeActivityIndicator() {
		let childVC = self.childViewControllers.first!
		let childView = childVC.view!

		UIView.animate(withDuration: animationDuration, animations: {
			childView.alpha = 0
		}) { _ in
			childView.removeFromSuperview()
			childVC.removeFromParentViewController()
		}
	}

	private func presentDoorStatus(_ doorId: String, _ status: String) {
		presentAlertController(withTitle: "\(doorId) is \(status)", andMessage: nil)
	}

	private struct DurationPickerOverlay {
		fileprivate var backgroundView: UIView
		fileprivate var picker: UIDatePicker
		fileprivate var toolbar: UIToolbar

		fileprivate var pendingTask: DoorTask.PendingLeaveOpen!

		init(within bounds: CGRect, autoresizingMask: UIViewAutoresizing) {
			backgroundView = UIView(frame: bounds)
			backgroundView.backgroundColor = .black
			backgroundView.autoresizingMask = autoresizingMask

			picker = UIDatePicker()
			picker.backgroundColor = .clear
			picker.datePickerMode = .countDownTimer
			picker.setValue(UIColor.white, forKey: "textColor")
			picker.autoresizingMask = autoresizingMask

			toolbar = UIToolbar()
			toolbar.barStyle = .black

			let setDurationLabel = UILabel(frame: CGRect.zero)
			setDurationLabel.text = "Set Duration"
			setDurationLabel.textColor = .white
			setDurationLabel.textAlignment = .center
			setDurationLabel.sizeToFit()
			let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

			toolbar.setItems([UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil), flexibleSpace,
			                  UIBarButtonItem(customView: setDurationLabel), flexibleSpace,
			                  UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)], animated: false)
			toolbar.sizeToFit()
		}

		func addCancelRecognizers(target: Any?, selector: Selector?) {
			backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: target, action: selector))
			let swipeDownRecognizer = UISwipeGestureRecognizer(target: target, action: selector)
			swipeDownRecognizer.direction = .down
			backgroundView.addGestureRecognizer(swipeDownRecognizer)
			toolbar.items!.first!.action = selector
		}

		func addDoneAction(selector: Selector?) {
			toolbar.items!.last!.action = selector
		}
	}
}

protocol DoorActionDelegate {
	func didAddToFavorites(doorId: String)

	func doorActionViewControllerWillDisappear()

	func credentialErrorDidOccur(_ error: SSHError)
}
