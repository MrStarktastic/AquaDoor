//
//  ActivityIndicatorViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 10/10/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit

class ActivityIndicatorViewController: UIViewController {
	@IBOutlet weak var stackView: UIStackView!
	@IBOutlet weak private var loadingLabel: UILabel!
	@IBOutlet weak private var activityIndicator: UIActivityIndicatorView!

	private lazy var text: String = ""

	convenience init(text: String) {
		self.init()
		self.text = text
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let autoresizingMask: UIViewAutoresizing = [.flexibleWidth, .flexibleHeight]

		stackView.autoresizingMask = autoresizingMask

		let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
		blurEffectView.frame = view.bounds
		blurEffectView.autoresizingMask = autoresizingMask
		view.insertSubview(blurEffectView, at: 0)

		loadingLabel.text = text
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.alpha = 0
		UIView.animate(withDuration: 0.3) { self.view.alpha = 1 }
		activityIndicator.startAnimating()
	}
}
