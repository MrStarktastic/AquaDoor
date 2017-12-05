//
//  DoorTask.swift
//  AquaDoor
//
//  Created by Ben Faingold on 10/4/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import Foundation

/*:
For more information, see [Door Opening/Closing.](http://wiki.cs.huji.ac.il/wiki/Door_Opening/Closing)
*/
class DoorTask {
	private var doorId: String!

	private var start: (() -> Void)?
	private var completion: ((Result) -> Void)?

	private var tryingAgain = false
	private var lastCommand: String!

	private var delegate: LeaveDoorOpenDelegate?

	public init(delegate: LeaveDoorOpenDelegate?) {
		self.delegate = delegate
	}

	func execute(kind: Kind, onDoorWithId doorId: String,
	             start: (() -> Void)?, completion: ((Result) -> Void)?) {
		self.doorId = doorId
		self.start = start
		self.completion = completion

		if kind == .leaveOpen {
			delegate!.needsDurationToLeaveDoorOpen(PendingLeaveOpen(self))
			return
		}

		sendCommand("door \(kind == .close ? doorId + " 0" : kind == .status ? "-s " + doorId : doorId)")
	}

	private func sendCommand(_ command: String) {
		start?()
		start = nil
		lastCommand = command

		SSHCommander.prepare(success: { instance in
			instance.execute(command: command, completion: self.parseOutput)
		}, failure: { error in
			self.completion?(.error(error)) }, force: tryingAgain)
	}

	private func parseOutput(_ output: String?) {
		guard let output = output else {
			if tryingAgain {
				tryingAgain = false
				completion?(.error(.executionFailed))
				return
			}

			tryingAgain = true
			sendCommand(lastCommand)

			return
		}

		if output.contains("Error") {
			completion?(.doorIdNotFound)
			return
		}

		if let statusStartIndex = output.range(of: ": ", options: .backwards)?.upperBound {
			completion?(.status(String(output[statusStartIndex ..< output.endIndex])))
		}
	}

	class PendingLeaveOpen {
		private var task: DoorTask

		public var doorId: String { get { return task.doorId }}

		fileprivate init(_ task: DoorTask) {
			self.task = task
		}

		func leaveOpen(for duration: Int) {
			task.sendCommand("door \(task.doorId) \(duration)")
		}

		deinit {
			task.delegate = nil
			task.start = nil
			task.completion = nil
		}
	}

	enum Kind: Int {
		case close, open, leaveOpen, status
	}

	enum Result {
		case status(String), error(SSHError), doorIdNotFound
	}
}

protocol LeaveDoorOpenDelegate {
	func needsDurationToLeaveDoorOpen(_ pendingTask: DoorTask.PendingLeaveOpen)
}
