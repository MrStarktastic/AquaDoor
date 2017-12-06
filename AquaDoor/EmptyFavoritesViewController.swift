//
//  EmptyFavoritesViewController.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/13/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit
import AVFoundation

class EmptyFavoritesViewController: UIViewController {
	@IBOutlet weak private var playerView: AVPlayerView!
	@IBOutlet weak private var instructionLabel: UILabel!

	// TODO: Consider using AVKit.AVPlayerViewController
	private var player: AVPlayer!

	var delegate: EmptyStateDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()

		player = AVPlayer(url: Bundle.main.url(forResource: "fish_and_doors_anim",
		                                       withExtension: "mov")!)
		(playerView.layer as! AVPlayerLayer).player = player
		player.isMuted = true
		player.actionAtItemEnd = .none
		try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)

		let notifCenter = NotificationCenter.default
		notifCenter.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil)
		{ _ in
			self.player.seek(to: kCMTimeZero)
		}

		notifCenter.addObserver(self, selector: #selector(appWillEnterForeground),
														name: .UIApplicationWillEnterForeground, object: nil)

		instructionLabel.isUserInteractionEnabled = true
		instructionLabel.addGestureRecognizer(UITapGestureRecognizer(
			target: self, action: #selector(didTapInstructionLabel)))
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		player.play()
	}

	override func didMove(toParentViewController parent: UIViewController?) {
		if parent != nil {
			delegate = parent as! EmptyStateDelegate
			return
		}

		NotificationCenter.default.removeObserver(self)

		UIView.animate(withDuration: 0.3, animations: {
			self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
		}, completion: { _ in self.view.removeFromSuperview() })
	}

	@objc func appWillEnterForeground() {
		player.play()
	}

	@objc func didTapInstructionLabel() {
		delegate.didTapInstructionLabel()
	}
}

protocol EmptyStateDelegate {
	/// Did tap on UILabel which instructs the user to tap the 🔍 button
	func didTapInstructionLabel()
}
