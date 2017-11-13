//
//  FavoriteDoor.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/24/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

struct FavoriteDoor {
	let id: String
	let nickname: String
	let colorId: String
}

class DoorUtil {
	private static let corrdiorOrTraklinIdPattern = "[AB][1-5]C[EW]"

	public static func isCorridorOrTraklin(_ doorId: String) -> Bool {
		return doorId.matches(regex: corrdiorOrTraklinIdPattern)
	}
}
