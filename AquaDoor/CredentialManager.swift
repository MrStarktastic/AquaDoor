//
//  CredentialManager.swift
//  AquaDoor
//
//  Created by Ben Faingold on 8/9/17.
//  Copyright © 2017 Ben Faingold. All rights reserved.
//

import KeychainSwift

/// Utility functions for managing credentials.
class CredentialManager {
	private static let KEY_USERNAME = "cs_user"
	private static let KEY_PASSWORD = "cs_pass"

	/// Synchronized with other devices through iCloud.
	private static let keychain = KeychainSwift(synchronizable: true)

	static func save(username: String, password: String) {
		keychain.set(username, forKey: KEY_USERNAME)
		keychain.set(password, forKey: KEY_PASSWORD)
	}

	/// Loads stored username and password strings.
	///
	/// - Returns: Pair of (username, password) or nil if any of them doesn't exist.
	static func load() -> (String, String)? {
		if let username = keychain.get(KEY_USERNAME),
			let password = keychain.get(KEY_PASSWORD) {
			return (username, password)
		}

		return nil
	}

	/// Deletes stored credentials - use solely for testing.
	static func reset() {
		keychain.delete(KEY_USERNAME)
		keychain.delete(KEY_PASSWORD)
	}
}
