//
//  UIRectButton.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/28/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

@IBDesignable
class BorderedRectButton: UIButton {
	@IBInspectable var cornerRadius: CGFloat = 5 { didSet { layer.cornerRadius = cornerRadius }}
	@IBInspectable var borderWidth: CGFloat = 2 { didSet { layer.borderWidth = borderWidth }}
	@IBInspectable var borderColor: UIColor = .white { didSet { layer.borderColor = borderColor.cgColor }}

	override func layoutSubviews() {
		super.layoutSubviews()

		layer.cornerRadius = cornerRadius
		layer.borderWidth = borderWidth
		layer.borderColor = borderColor.cgColor
	}
}
