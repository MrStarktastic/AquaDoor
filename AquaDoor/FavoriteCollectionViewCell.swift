//
//  FavoriteCollectionViewCell.swift
//  AquaDoor
//
//  Created by Ben Faingold on 10/1/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

@IBDesignable
class FavoriteCollectionViewCell: UICollectionViewCell {
	@IBOutlet private weak var title: UILabel!
	@IBOutlet private weak var subtitle: UILabel!

	/// Instead of dealing with nil and optionals we use an empty string.
	/// Setting the text of a UILabel to this makes the parent UIStackView
	/// ignore its existence, i.e. the other UILabel will be centered vertically.
	private let emptyString = ""

	private var hasNickname = false

	public var isCorridorOrTraklin: Bool!

	var doorId: String {
		get { return hasNickname ? subtitle.text! : title.text! }
		set {
			hasNickname ? (subtitle.text = newValue) : (title.text = newValue)
			isCorridorOrTraklin = DoorUtil.isCorridorOrTraklin(newValue)
		}
	}

	var nickname: String {
		get { return hasNickname ? title.text! : emptyString }
		set {
			if newValue != emptyString {
				subtitle.text = doorId
				title.text = newValue
				hasNickname = true
			} else {
				title.text = doorId
				subtitle.text = emptyString
				hasNickname = false
			}
		}
	}

	var gradient: UIGradient {
		get {
			let view = backgroundView as! GradientView
			return UIGradient(colorTop: view.colorTop!, colorBottom: view.colorBottom!)
		}
		set {
			let view = GradientView(frame: bounds)
			view.colorTop = newValue.colorTop
			view.colorBottom = newValue.colorBottom
			backgroundView = view
		}
	}

	var titleText: String { get { return title.text! }}

	var delegate: FavoriteCollectionViewCellDelegate?

	override func layoutSubviews() {
		super.layoutSubviews()
		addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPress)))
	}

	@objc private func didLongPress(_ recognizer: UILongPressGestureRecognizer) {
		if recognizer.state == .began {
			delegate?.didLongPress(cell: self)
		}
	}
}

protocol FavoriteCollectionViewCellDelegate {
	func didLongPress(cell: FavoriteCollectionViewCell)
}
