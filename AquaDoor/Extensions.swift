//
//  Extensions.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/8/17.
//  Copyright © 2017 Ben Faingold. All rights reserved.
//

import Foundation
import UIKit
import KeychainSwift

public extension String {
	func trimWhitespaces() -> String {
		return trimmingCharacters(in: .whitespaces)
	}

	func matches(regex: String) -> Bool {
		return range(of: regex, options: .regularExpression) != nil
	}
}

public extension Array where Element == [String] {
	mutating func moveElement(fromArrayAt srcArrayIndex: Int, atCell srcCellIndex: Int,
	                          toArrayAt destArrayIndex: Int, atCell destCellIndex: Int) {
		self[destArrayIndex].insert(self[srcArrayIndex].remove(at: srcCellIndex), at: destCellIndex)
	}
}

public extension Array where Element == UIView {
	var isUserInteractionEnabled: Bool {
		get { return !contains { !$0.isUserInteractionEnabled }}
		set { forEach { $0.isUserInteractionEnabled = newValue }}
	}
}

public extension ImplicitlyUnwrappedOptional where Wrapped == Int {
	static postfix func ++(x: inout Int!) -> Int! {
		defer { x = x + 1 }
		return x
	}
}

public extension UIImage {
	/// Tint, Colorize image with given tint color
	/// This is similar to Photoshop's "Color" layer blend mode
	/// This is perfect for non-greyscale source images, and images that
	/// have both highlights and shadows that should be preserved<br><br>
	/// white will stay white and black will stay black as the lightness of
	/// the image is preserved.
	///
	/// - Parameter fillColor: The color that the image should be tinted to.
	/// - Returns:  Tinted image.
	public func tintImage(with fillColor: UIColor) -> UIImage {
		return modifiedImage { context, rect in
			// draw black background - workaround to preserve color of partially transparent pixels
			context.setBlendMode(.normal)
			UIColor.black.setFill()
			context.fill(rect)

			// draw original image
			context.setBlendMode(.normal)
			context.draw(cgImage!, in: rect)

			// tint image (loosing alpha) - the luminosity of the original image is preserved
			context.setBlendMode(.color)
			fillColor.setFill()
			context.fill(rect)

			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(context.makeImage()!, in: rect)
		}
	}

	/// Tint pictogram with color
	/// Method work on single colors without fading, mainly for svg images
	///
	/// - Parameter fillColor: TintColor: Tint color
	/// - Returns:             Tinted image
	public func tintPictogram(with fillColor: UIColor) -> UIImage {
		return modifiedImage { context, rect in
			// draw tint color
			context.setBlendMode(.normal)
			fillColor.setFill()
			context.fill(rect)

			// mask by alpha values of original image
			context.setBlendMode(.destinationIn)
			context.draw(cgImage!, in: rect)
		}
	}

	/// Modified Image Context, apply modification on image
	///
	/// - Parameter draw: (CGContext, CGRect) -> ())
	/// - Returns:        UIImage
	private func modifiedImage(_ draw: (CGContext, CGRect) -> ()) -> UIImage {
		// using scale correctly preserves retina images
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		let context: CGContext! = UIGraphicsGetCurrentContext()
		assert(context != nil)

		// correctly rotate image
		context.translateBy(x: 0, y: size.height)
		context.scaleBy(x: 1.0, y: -1.0)

		let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)

		draw(context, rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
}

public extension UIColor {
	convenience init?(hexString: String) {
		let r, g, b, a: CGFloat

		if hexString.hasPrefix("#") {
			let start = hexString.index(hexString.startIndex, offsetBy: 1)
			let hexColor = String(hexString[start...])

			if hexColor.count == 8 {
				let scanner = Scanner(string: hexColor)
				var hexNumber: UInt64 = 0

				if scanner.scanHexInt64(&hexNumber) {
					r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
					g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
					b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
					a = CGFloat(hexNumber & 0x000000ff) / 255

					self.init(red: r, green: g, blue: b, alpha: a)
					return
				}
			}
		}

		return nil
	}
}

public extension KeychainSwift {
	convenience init(synchronizable: Bool) {
		self.init()
		self.synchronizable = synchronizable
	}
}
