import GRDBCipher
import SignalProtocol

// TODO simplify error handling
// maybe try and get rid of stringly sqls

final class SQLCipherPreKeyStore: PreKeyStore {
  private let dbQueue: DatabaseQueue

  init(dbQueue: DatabaseQueue) {
    self.dbQueue = dbQueue
  }

  func load(preKey: UInt32) -> Data? {
    do {
      return try dbQueue.read { db in
        return try Data.fetchOne(db, "SELECT pre_key FROM pre_key_store WHERE id = ?", arguments: [preKey])
      }
    } catch {
      print("[error] SQLCipherPreKeyStore.load(preKey: \(preKey))", error.localizedDescription)
      return nil
    }
  }

  func store(preKey: Data, for id: UInt32) -> Bool {
    do {
      try dbQueue.write { db in
        try db.execute("INSERT INTO pre_key_store (id, pre_key) VALUES (?, ?)", arguments: [id, preKey])
      }
      return true
    } catch {
      print("[error] SQLCipherPreKeyStore.store(preKey: <???>, for: \(id))", error.localizedDescription)
      return false
    }
  }

  func contains(preKey: UInt32) -> Bool {
    do {
      return try dbQueue.read { db in
        let count = try Int.fetchOne(db, "SELECT count(*) FROM pre_key_store WHERE id = ?", arguments: [preKey])!
        return count >= 1
      }
    } catch {
      print("[error] SQLCipherPreKeyStore.contains(preKey: \(preKey))", error.localizedDescription)
      return false
    }
  }

  func remove(preKey: UInt32) -> Bool {
    do {
      try dbQueue.write { db -> Void in
        try db.execute("DELETE FROM pre_key_store WHERE id = ?", arguments: [preKey])
      }
      return true
    } catch {
      print("[error] SQLCipherPreKeyStore.remove(preKey: \(preKey))", error.localizedDescription)
      return false
    }
  }
}

// MARK: -
final class SQLCipherIdentityKeyStore: IdentityKeyStore {
  private let dbQueue: DatabaseQueue
  private let identity: KeyPair
  private let registrationId: UInt32

  init(dbQueue: DatabaseQueue, identity: KeyPair, registrationId: UInt32) {
    self.dbQueue = dbQueue
    self.identity = identity
    self.registrationId = registrationId
  }

  func identityKeyPair() -> KeyPair? {
    return identity
  }

  func localRegistrationId() -> UInt32? {
    return registrationId
  }

  func save(identity: Data?, for address: SignalAddress) -> Bool {
    do {
      try dbQueue.write { db in
        try db.execute("""
          INSERT OR REPLACE INTO identity_key_store (name, device_id, identity) VALUES (?, ?, ?)
          """, arguments: [address.name, address.deviceId, identity])
      }
      return true
    } catch {
      print("[error] SQLCipherIdentityKeyStore.save(identity: <???>, for address: \(address))", error.localizedDescription)
      return false
    }
  }

  func isTrusted(identity: Data, for address: SignalAddress) -> Bool? {
    do {
      return try dbQueue.read { db in
        guard let fetchedIdentity = try Data.fetchOne(db, """
          SELECT identity FROM identity_key_store WHERE name = ? AND device_id = ?
          """, arguments: [address.name, address.deviceId]) else { return true }
        return fetchedIdentity == identity
      }
    } catch {
      print("[error] SQLCipherIdentityKeyStore.isTrusted(identity: <???>, for address: \(address))", error.localizedDescription)
      return false
    }
  }
}

// MARK: -
final class SQLCipherSessionStore: SessionStore {
  private let dbQueue: DatabaseQueue

  init(dbQueue: DatabaseQueue) {
    self.dbQueue = dbQueue
  }

  func loadSession(for address: SignalAddress) -> (session: Data, userRecord: Data?)? {
    do {
      return try dbQueue.read { db in
        if let row = try Row.fetchOne(db,
                                      "SELECT session, user_record FROM session_store WHERE name = ? AND device_id = ?",
                                      arguments: [address.name, address.deviceId]) {
          return (session: row["session"], userRecord: row["user_record"])
        } else {
          return nil
        }
      }
    } catch {
      print("[error] SQLCipherSessionStore.loadSession(for address: \(address))", error.localizedDescription)
      return nil
    }
  }

  func subDeviceSessions(for name: String) -> [Int32]? {
    do {
      return try dbQueue.read { db in
        return try Int32.fetchAll(db, "SELECT device_id FROM session_store WHERE name = ?", arguments: [name])
      }
    } catch {
      print("[error] SQLCipherSessionStore.subDeviceSessions(for name: \(name))", error.localizedDescription)
      return nil
    }
  }

  func store(session: Data, for address: SignalAddress, userRecord: Data?) -> Bool {
    do {
      try dbQueue.write { db in
        try db.execute("""
          INSERT OR REPLACE INTO session_store (name, device_id, session, user_record) VALUES (?, ?, ?, ?)
          """, arguments: [address.name, address.deviceId, session, userRecord])
      }
      return true
    } catch {
      print("[error] SQLCipherSessionStore.store(session: <???>, address: \(address), userRecord: <???>)", error.localizedDescription)
      return false
    }
  }

  func containsSession(for address: SignalAddress) -> Bool {
    do {
      return try dbQueue.read { db in
        let count = try Int.fetchOne(db,
                                     "SELECT count(*) FROM session_store WHERE name = ? AND device_id = ?",
                                     arguments: [address.name, address.deviceId])!
        return count >= 1
      }
    } catch {
      print("[error] SQLCipherSessionStore.containsSession(for address: \(address))", error.localizedDescription)
      return false
    }
  }

  func deleteSession(for address: SignalAddress) -> Bool? {
    do {
      try dbQueue.write { db in
        try db.execute("DELETE FROM session_store WHERE name = ? AND device_id = ?",
                       arguments: [address.name, address.deviceId])
      }
      return true
    } catch {
      print("[error] SQLCipherSessionStore.deleteSession(for address: \(address))", error.localizedDescription)
      return nil
    }
  }

  func deleteAllSessions(for name: String) -> Int? {
    do {
      return try dbQueue.write { db in
        try db.execute("DELETE FROM session_store WHERE name = ?", arguments: [name])
        // TODO
        return nil
      }
    } catch {
      print("[error] SQLCipherSessionStore.deleteAllSessions(for name: \(name))", error.localizedDescription)
      return nil
    }
  }
}

// MARK: -
final class SQLCipherSignedPreKeyStore: SignedPreKeyStore {
  private let dbQueue: DatabaseQueue

  init(dbQueue: DatabaseQueue) {
    self.dbQueue = dbQueue
  }

  func load(signedPreKey: UInt32) -> Data? {
    do {
      return try dbQueue.read { db in
        return try Data.fetchOne(db, "SELECT signed_pre_key FROM signed_pre_key_store WHERE id = ?", arguments: [signedPreKey])
      }
    } catch {
      print("[error] SQLCipherSignedPreKeyStore.load(signedPreKey: \(signedPreKey))", error.localizedDescription)
      return nil
    }
  }

  func store(signedPreKey: Data, for id: UInt32) -> Bool {
    do {
      try dbQueue.write { db in
        try db.execute("INSERT INTO signed_pre_key_store (id, signed_pre_key) VALUES (?, ?)",
                       arguments: [id, signedPreKey])
      }
      return true
    } catch {
      print("[error] SQLCipherSignedPreKeyStore.store(signedPreKey: <???>, for id: \(id))", error.localizedDescription)
      return false
    }
  }

  func contains(signedPreKey: UInt32) -> Bool {
    do {
      return try dbQueue.read { db in
        let count = try Int.fetchOne(db, "SELECT count(*) FROM signed_pre_key_store WHERE id = ?", arguments: [signedPreKey])!
        return count >= 1
      }
    } catch {
      print("[error] SQLCipherSignedPreKeyStore.contains(signedPreKey: \(signedPreKey))", error.localizedDescription)
      return false
    }
  }

  func remove(signedPreKey: UInt32) -> Bool {
    do {
      try dbQueue.write { db -> Void in
        try db.execute("DELETE FROM signed_pre_key_store WHERE id = ?", arguments: [signedPreKey])
      }
      return true
    } catch {
      print("[error] SQLCipherSignedPreKeyStore.remove(signedPreKey: \(signedPreKey))", error.localizedDescription)
      return false
    }
  }
}
