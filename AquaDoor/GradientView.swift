//
//  GradientView.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/23/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
	@IBInspectable var colorTop: UIColor? { didSet { layerGradient(colorTop: colorTop, colorBottom: colorBottom) }}
	@IBInspectable var colorBottom: UIColor? { didSet { layerGradient(colorTop: colorTop, colorBottom: colorBottom) }}

	override func layoutSubviews() {
		super.layoutSubviews()
		layerGradient(colorTop: colorTop, colorBottom: colorBottom)
	}

	func layerGradient(colorTop:UIColor?, colorBottom:UIColor?) {
		if let top = colorTop?.cgColor, let bottom = colorBottom?.cgColor {
			if let existingGradientLayer = layer.sublayers?.first {
				existingGradientLayer.frame = layer.bounds
				return
			}

			let gradientLayer = CAGradientLayer()
			gradientLayer.frame = layer.bounds
			gradientLayer.colors = [top, bottom]
			layer.addSublayer(gradientLayer)
		}
	}
}

struct UIGradient {
	private static let gradients = [
		"cyan": UIGradient(topHex: "#51f1fcff", bottomHex: "#5ac8faff"),
		"yellow": UIGradient(topHex: "#ff8d00ff", bottomHex: "#ffcc00ff"),
		"orange": UIGradient(topHex: "#ff9500ff", bottomHex: "#ff6b00ff"),
		"pink": UIGradient(topHex: "#ff2d55ff", bottomHex: "#ff2676ff"),
		"blue": UIGradient(topHex: "#00b9ffff", bottomHex: "#007affff"),
		"green": UIGradient(topHex: "#4cd964ff", bottomHex: "#18b536ff"),
		"red": UIGradient(topHex: "#ff3b30ff", bottomHex: "#e60200ff"),
		"gray": UIGradient(topHex: "#8e8e93ff", bottomHex: "#68686eff")
	]

	private static let defaultGradient = gradients["gray"]!

	var colorTop: UIColor
	var colorBottom: UIColor

	init(colorTop: UIColor, colorBottom: UIColor) {
		self.colorTop = colorTop
		self.colorBottom = colorBottom
	}

	init(topHex: String, bottomHex: String) {
		colorTop = UIColor(hexString: topHex)!
		colorBottom = UIColor(hexString: bottomHex)!
	}

	public static func get(byId key: String = "") -> UIGradient {
		return gradients[key, default: defaultGradient]
	}
}
