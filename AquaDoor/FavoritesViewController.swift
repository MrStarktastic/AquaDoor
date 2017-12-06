//
//  FavoritesViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/24/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

class FavoritesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
CredentialAlertDelegate, DoorActionDelegate, EmptyStateDelegate, FavoriteCollectionViewCellDelegate {
	private let sectionCount = 1
	private let itemsPerRow: CGFloat = 2
	private let cellInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)

	private var doorTask: DoorTask!
	private var database: Database!
	private var doorCount: Int!
	private var recentlyAddedDoorId: String?

	override func viewDidLoad() {
		super.viewDidLoad()

		database = .shared
		doorCount = database.count
		if doorCount == 0 { presentChildViewController(withIdentifier: "EmptyFavorites") }

		prepareSSHCommander()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = true
			navigationItem.largeTitleDisplayMode = .always
		}
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return sectionCount
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return doorCount
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FavoriteCollectionViewCell

		// Avoid fetching the recently added door from the database
		// because IO operations are expensive, am I right?
		if recentlyAddedDoorId != nil {
			cell.doorId = recentlyAddedDoorId!
			cell.nickname = ""
			cell.gradient = .get()
			recentlyAddedDoorId = nil
		} else {
			let door = try! database.get(doorAtIndex: indexPath.item)!
			cell.doorId = door.id
			cell.nickname = door.nickname
			cell.gradient = .get(byId: door.colorId)
		}

		if cell.delegate == nil { cell.delegate = self }

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
											sizeForItemAt indexPath: IndexPath) -> CGSize {
		let widthPerItem = (view.frame.width - cellInsets.left * (itemsPerRow + 1)) / itemsPerRow
		return CGSize(width: widthPerItem, height: widthPerItem / 2)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
											insetForSectionAt section: Int) -> UIEdgeInsets {
		return cellInsets
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
											minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return cellInsets.left
	}

	internal func didLongPress(cell: FavoriteCollectionViewCell) {
		do { try database.delete(doorWithId: cell.doorId) }
		catch { return }

		if --doorCount == 0 { presentChildViewController(withIdentifier: "EmptyFavorites") }

		if let indexPath = collectionView?.indexPath(for: cell) {
			collectionView!.deleteItems(at: [indexPath])
		}
	}

	/// Makes sure that an SSH session is created (if possible) before actual usage
	/// and does not care if the error is not related to credentials.
	private func prepareSSHCommander() {
		SSHCommander.prepare(success: nil, failure: credentialErrorDidOccur, force: false)
	}

	private func presentCredentialsAlertController(withTitle title: String) {
		let dialog = CredentialAlertControllerWrapper(title: title,
																									message: "To proceed, please enter your CSE username and password",
																									delegate: self, cancellable: false).controller

		if let (username, password) = SSHCommander.credentials {
			let textFields = dialog.textFields!
			textFields[0].text = username
			textFields[1].text = password
		}

		present(dialog, animated: true, completion: nil)
	}

	func didSetCredentials(username: String, password: String) {
		SSHCommander.credentials = (username, password)
		prepareSSHCommander()
	}

	private func presentChildViewController(withIdentifier identifier: String) {
		let controller = storyboard!.instantiateViewController(withIdentifier: identifier)
		addChildViewController(controller)
		view.addSubview(controller.view)
		controller.didMove(toParentViewController: self)
	}

	private func presentDoorActionViewController() {
		navigationController?.setNavigationBarHidden(true, animated: true)
		presentChildViewController(withIdentifier: "DoorAction")
	}

	@IBAction func didTapSearchButton(_ sender: UIBarButtonItem) {
		presentDoorActionViewController()
	}

	func didAddToFavorites(doorId: String) {
		if doorCount == 0 {
			(childViewControllers.first as! EmptyFavoritesViewController).removeFromParentViewController()
		}

		recentlyAddedDoorId = doorId
		collectionView?.insertItems(at: [IndexPath(item: doorCount++, section: 0)])
	}

	func doorActionViewControllerWillDisappear() {
		navigationController?.setNavigationBarHidden(false, animated: true)
	}

	func credentialErrorDidOccur(_ error: SSHError) {
		switch error {
		case .credentialsNotFound:
			self.presentCredentialsAlertController(withTitle: "Enter Credentials")
		case .authenticationFailed:
			self.presentCredentialsAlertController(withTitle: "Incorrect Username or Password")
		default:
			break
		}
	}

	func didTapInstructionLabel() {
		presentDoorActionViewController()
	}
}
