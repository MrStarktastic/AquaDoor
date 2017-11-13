//
//  AVPlayerView.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/13/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {
	override class var layerClass: AnyClass {
		return AVPlayerLayer.self
	}
}
