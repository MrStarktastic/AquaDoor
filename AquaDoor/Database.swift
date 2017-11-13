//
//  Database.swift
//  AquaDoor
//
//  Created by Ben Faingold on 9/24/17.
//  Copyright © 2017 Ben Faingold and Yossi Konstantinovsky. All rights reserved.
//

import SQLite

/// A singleton-based database class for managing favorite doors.
class Database {
	public static let shared = Database()

	private let dbPath: String
	private let db: Connection

	private let table = Table("favoriteDoors")
	private let doorIdExp = Expression<String>("doorId")
	private let nicknameExp = Expression<String>("nickname")
	private let colorIdExp = Expression<String>("colorId")

	public var count: Int { get { return (try? db.scalar(table.count)) ?? 0 }}

	private init() {
		dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/db.sqlite3"
		db = try! Connection(dbPath)

		try! db.run(table.create(ifNotExists: true) { t in
			t.column(doorIdExp, primaryKey: true)
			t.column(nicknameExp)
			t.column(colorIdExp)
		})
	}

	/// Transforms a row from the database's table into a convenient plain object which can be used
	/// in places outside of this class, thus obviating the need to use SQL expressions.
	///
	/// - Parameter row: Row from the database's table which represents a door and its properties.
	/// - Returns: A FavoriteDoor object representing the row's values.
	private func generateDoor(fromRow row: Row) -> FavoriteDoor {
		return FavoriteDoor(id: row[doorIdExp], nickname: row[nicknameExp], colorId: row[colorIdExp])
	}

	public func get(doorWithId doorId: String) throws -> FavoriteDoor? {
		if let row = try db.pluck(table.where(doorIdExp == doorId)) {
			return generateDoor(fromRow: row)
		}

		return nil
	}

	public func get(doorAtIndex index: Int) throws -> FavoriteDoor? {
		if let row = try db.pluck(table.limit(1, offset: index)) {
			return generateDoor(fromRow: row)
		}

		return nil
	}

	/// Adds a door and its properties to favorites.
	///
	/// - Parameters:
	///   - doorId: ID of the door to be added (expected to be uppercased, for consistency).
	///   - nickname: Nickname of the door to be added.
	///   - colorId: Color identifier of the door to be added.
	/// - Returns: True if successful, false if door with such ID has already been added.
	/// - Throws: An SQLite error if any of the IO operations (besides the primaryKey constraint) go wrong.
	public func add(doorWithId doorId: String, nickname: String = "", colorId: String = "") throws -> Bool {
		do {
			try db.run(table.insert(doorIdExp <- doorId, nicknameExp <- nickname, colorIdExp <- colorId))
		} catch let Result.error(_, code, _) where code == SQLITE_CONSTRAINT {
			return false
		}

		return true
	}

	/// Swaps between two saved doors. The order is important, i.e. the first door
	/// takes the row of the second and vice versa. Hence, this is done by swapping
	/// all of the values of each other's row, rather than simply swapping the row ID.
	///
	/// - Parameters:
	///   - doorId1: The first door ID.
	///   - doorId2: The second door ID.
	/// - Throws: An SQLite error if any of the IO operations go wrong.
	public func swap(doorId doorId1: String, withDoorId doorId2: String) throws {
		let t1 = table.where(doorIdExp == doorId1)
		let t2 = table.where(doorIdExp == doorId2)

		if let row1 = try db.pluck(t1), let row2 = try db.pluck(t2) {
			try db.transaction {
				try self.db.run(t1.update(self.doorIdExp <- row2[self.doorIdExp],
				                          self.nicknameExp <- row2[self.nicknameExp],
				                          self.colorIdExp <- row2[self.colorIdExp]))
				try self.db.run(t2.update(self.doorIdExp <- row1[self.doorIdExp],
				                          self.nicknameExp <- row1[self.nicknameExp],
				                          self.colorIdExp <- row1[self.colorIdExp]))
			}
		}
	}

	public func delete(doorWithId doorId: String) throws {
		try db.run(table.where(doorIdExp == doorId).delete())
	}
}
