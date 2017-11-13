//
//  UIRoundProgressButton.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/24/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

class RoundProgressButton: UIButton, CAAnimationDelegate {
	@IBInspectable var ringWidth: CGFloat = 2 {
		didSet {
			initRing(mainRingLayer, withColor: color)
			initRing(progressRingLayer, withColor: progressRingColor)
		}
	}
	@IBInspectable var innerCirclePadding: CGFloat = 6 { didSet { initInnerCircle() }}
	@IBInspectable var color: UIColor = .black { didSet { initInnerCircle() }}
	@IBInspectable var progressRingColor: UIColor = .white {
		didSet { initRing(progressRingLayer, withColor: progressRingColor) }
	}

	private var innerCircleLayer: CAShapeLayer!
	private var mainRingLayer: CAShapeLayer!
	private var progressRingLayer: CAShapeLayer!
	private var checkmarkLayer: CALayer!

	private var size: CGFloat!
	private var radius: CGFloat!
	private var midPoint: CGPoint!
	private var innerCircleScaleFactor: CGFloat!

	private let notifyAnimationEndKey = "shouldNotifyAnimationEnd"

	public var delegate: ProgressButtonDelegate?

	private let fadeInAnimation: CAAnimation = {
		let anim = CABasicAnimation(keyPath: "opacity")
		anim.fromValue = 0
		anim.toValue = 1
		anim.duration = 0.2

		return anim
	}()

	private let fadeOutAnimation: CAAnimation = {
		let anim = CABasicAnimation(keyPath: "opacity")
		anim.fromValue = 1
		anim.toValue = 0
		anim.duration = 0.2

		return anim
	}()

	private let strokeAnimationGroup: CAAnimation = {
		let inAnim = CABasicAnimation(keyPath: "strokeEnd")
		inAnim.fromValue = 0
		inAnim.toValue = 1
		inAnim.duration = 1
		inAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)

		let outAnim = CABasicAnimation(keyPath: "strokeStart")
		outAnim.beginTime = 0.5
		outAnim.fromValue = 0
		outAnim.toValue = 1
		outAnim.duration = 1
		outAnim.timingFunction = CAMediaTimingFunction(name:  kCAMediaTimingFunctionEaseOut)

		let groupAnim = CAAnimationGroup()
		groupAnim.duration = outAnim.beginTime + 1
		groupAnim.repeatCount = .infinity
		groupAnim.animations = [inAnim, outAnim]

		return groupAnim
	}()

	private let rotationAnimation: CAAnimation = {
		let anim = CABasicAnimation(keyPath: "transform.rotation.z")
		anim.fromValue = 0
		anim.toValue = 2 * Float.pi
		anim.duration = 2
		anim.repeatCount = .infinity

		return anim
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		addSublayers()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		addSublayers()
	}

	private func addSublayers() {
		size = frame.size.width
		radius = size / 2
		midPoint = CGPoint(x: radius, y: radius)

		innerCircleLayer = CAShapeLayer()
		progressRingLayer = CAShapeLayer()
		mainRingLayer = CAShapeLayer()
		checkmarkLayer = CALayer()

		layer.addSublayer(innerCircleLayer)
		layer.addSublayer(mainRingLayer)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		layer.cornerRadius = radius

		initRing(mainRingLayer, withColor: color)
		initRing(progressRingLayer, withColor: progressRingColor)
		initInnerCircle()
		initCheckmark()
	}

	private func initRing(_ ringLayer: CAShapeLayer, withColor color: UIColor) {
		let circlePath = UIBezierPath(arcCenter: midPoint, radius: radius - ringWidth * 1.5,
		                              startAngle: CGFloat(-.pi / 2.0),
		                              endAngle: CGFloat(.pi * 1.5), clockwise: true)
		ringLayer.bounds = bounds
		ringLayer.position = midPoint
		ringLayer.path = circlePath.cgPath
		ringLayer.fillColor = UIColor.clear.cgColor
		ringLayer.strokeColor = color.cgColor
		ringLayer.lineWidth = ringWidth
	}

	private func initInnerCircle() {
		let shapeSize = size - innerCirclePadding * 2
		let roundedRect = CGRect(origin: CGPoint(x: bounds.origin.x + innerCirclePadding,
		                                         y: bounds.origin.y + innerCirclePadding),
		                         size: CGSize(width: shapeSize, height: shapeSize))
		innerCircleLayer.bounds = roundedRect
		innerCircleLayer.position = midPoint
		innerCircleLayer.path = UIBezierPath(roundedRect: roundedRect,
		                                     cornerRadius: shapeSize / 2).cgPath
		innerCircleLayer.fillColor = color.cgColor
		innerCircleScaleFactor = (size - ringWidth * 2) / shapeSize
	}

	private func initCheckmark() {
		checkmarkLayer.bounds = bounds
		checkmarkLayer.position = midPoint
		checkmarkLayer.backgroundColor = UIColor.clear.cgColor
		checkmarkLayer.contentsGravity = kCAGravityCenter
		checkmarkLayer.contentsScale = UIScreen.main.scale
		checkmarkLayer.rasterizationScale = UIScreen.main.scale
		checkmarkLayer.shouldRasterize = true
		checkmarkLayer.contents = UIImage(named: "Checkmark")?
			.tintPictogram(with: progressRingColor).cgImage
	}

	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		if flag {
			if progressRingLayer.superlayer != nil {
				progressRingLayer.removeFromSuperlayer()
				progressRingLayer.removeAllAnimations()
				progressRingLayer.opacity = 1
			} else {
				checkmarkLayer.removeFromSuperlayer()
				checkmarkLayer.opacity = 1
			}

			if anim.value(forKey: notifyAnimationEndKey) as! Bool {
				delegate?.progressAnimationDidStop(self)
				isUserInteractionEnabled = true
			}
		}
	}

	public func animateProgress() {
		isUserInteractionEnabled = false

		layer.addSublayer(progressRingLayer)
		progressRingLayer.add(fadeInAnimation, forKey: nil)
		progressRingLayer.add(strokeAnimationGroup, forKey: nil)
		progressRingLayer.add(rotationAnimation, forKey: nil)
	}

	public func stopProgressAnimation(success: Bool) {
		// Hide progress ring
		fadeOutAnimation.delegate = self
		fadeOutAnimation.setValue(!success, forKey: notifyAnimationEndKey)
		progressRingLayer.opacity = 0
		progressRingLayer.add(fadeOutAnimation, forKey: nil)

		if success {
			let duration = 0.3
			showCheckmark(forDuration: duration)
			DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
				self.hideCheckmark(forDuration: duration)
			}
		}
	}

	private func showCheckmark(forDuration duration: CFTimeInterval) {
		if let titleLayer = titleLabel?.layer {
			let titleFadeOutAnim = fadeOutAnimation.copy() as! CAAnimation
			titleFadeOutAnim.delegate = nil
			titleFadeOutAnim.setValue(false, forKey: notifyAnimationEndKey)
			titleLayer.opacity = 0
			titleLayer.add(titleFadeOutAnim, forKey: nil)
		}

		innerCircleLayer.transform = CATransform3DMakeScale(innerCircleScaleFactor,
		                                                    innerCircleScaleFactor, 1)
		innerCircleLayer.add({
			let anim = CABasicAnimation(keyPath: "transform.scale")
			anim.fromValue = 1
			anim.toValue = innerCircleScaleFactor
			anim.duration = duration

			return anim
		}(), forKey: nil)

		layer.addSublayer(checkmarkLayer)
		checkmarkLayer.transform = CATransform3DMakeScale(1, 1, 1)
		checkmarkLayer.add({
			let anim = CABasicAnimation(keyPath: "transform.scale")
			anim.fromValue = 0
			anim.toValue = 1
			anim.duration = duration
			anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)

			return anim
		}(), forKey: nil)
		checkmarkLayer.add(fadeInAnimation, forKey: nil)
	}

	private func hideCheckmark(forDuration duration: CFTimeInterval) {
		fadeOutAnimation.setValue(true, forKey: notifyAnimationEndKey)
		checkmarkLayer.transform = CATransform3DMakeScale(0, 0, 0)
		checkmarkLayer.add({
			let anim = CABasicAnimation(keyPath: "transform.scale")
			anim.fromValue = 1
			anim.toValue = 0
			anim.duration = duration
			anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)

			return anim
		}(), forKey: nil)
		checkmarkLayer.add(fadeOutAnimation, forKey: nil)

		innerCircleLayer.transform = CATransform3DMakeScale(1, 1, 1)
		innerCircleLayer.add({
			let anim = CABasicAnimation(keyPath: "transform.scale")
			anim.fromValue = innerCircleScaleFactor
			anim.toValue = 1
			anim.duration = duration

			return anim
		}(), forKey: nil)

		if let titleLayer = titleLabel?.layer {
			titleLayer.opacity = 1
			titleLayer.add(fadeInAnimation, forKey: nil)
		}
	}
}

protocol ProgressButtonDelegate {
	func progressAnimationDidStop(_ sender: RoundProgressButton)
}
