//
//  SSHCommander.swift
//  AquaDoor
//
//  Created by Ben Faingold on 10/6/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import NMSSH

class SSHCommander {
	private static let shared = SSHCommander()

	public static var credentials = CredentialManager.load()

	private let host: String = "pond.cs.huji.ac.il"

	private let sshQueue = DispatchQueue(label: "SSH Queue")
	private let mainQueue = DispatchQueue.main

	private var session: NMSSHSession?

	private init() {}

	public static func prepare(success: ((SSHCommander) -> Void)?, failure: @escaping (SSHError) -> Void, force: Bool) {
		guard credentials != nil else {
			failure(.credentialsNotFound)
			return
		}

		shared.sshQueue.async {
			if !force, let session = shared.session, session.isConnected && session.isAuthorized {
				shared.mainQueue.async { success?(shared) }
				return
			}

			shared.connect(success, failure)
		}
	}

	private func connect(_ success: ((SSHCommander) -> Void)?, _ failure: @escaping (SSHError) -> Void) {
		let (username, password) = SSHCommander.credentials!

		if let oldSession = session { if oldSession.isConnected { oldSession.disconnect(); session = nil }}
		let newSession = NMSSHSession(host: host, andUsername: username)!

		do {
			if !newSession.connect() {
				// Connection does not care for validity of username and is assuming
				// that the user is connected to the right network, host should be found.
				// Hence this is purely a network connectivity error.
				throw SSHError.connectionFailed
			}

			newSession.authenticateByKeyboardInteractive { _ in return password }

			if !newSession.isAuthorized {
				throw SSHError.authenticationFailed
			}
		} catch let error {
			mainQueue.async { failure(error as! SSHError) }
			return
		}

		session = newSession
		mainQueue.async { success?(.shared) }
	}

	public func execute(command: String, completion: @escaping (String?) -> Void) {
		sshQueue.async {
			let output = try? self.session!.channel.execute(command)
			self.mainQueue.async { completion(output) }
		}
	}
}

enum SSHError: Error {
	// before connection
	case credentialsNotFound

	// on connection
	case connectionFailed

	// after connection
	case authenticationFailed

	// on execution
	case executionFailed
}
