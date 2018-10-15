import GRDBCipher

enum AppDatabase {
  enum Kind {
    case inMemory
    case temp
    case onDisk(path: String)
  }

  static func open(_ kind: Kind, passphrase: String) throws -> DatabaseQueue {
    let dbQueue: DatabaseQueue
    var configuration = Configuration()
    configuration.passphrase = passphrase
//    configuration.trace = {
//      print($0)
//    }

    switch kind {
    case .inMemory: dbQueue = DatabaseQueue(configuration: configuration)
    case .temp: dbQueue = try DatabaseQueue(path: "", configuration: configuration)
    case let .onDisk(path: path): dbQueue = try DatabaseQueue(path: path, configuration: configuration)
    }

    try migrator.migrate(dbQueue)
    return dbQueue
  }

  static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("create_signal_stores") { db in
      try db.create(table: "pre_key_store") { t in
        t.column("id", .integer).primaryKey()
        t.column("pre_key", .blob).notNull()
      }

      try db.create(table: "signed_pre_key_store") { t in
        t.column("id", .integer).primaryKey()
        t.column("signed_pre_key", .blob).notNull()
      }

      try db.create(table: "identity_key_store") { t in
        t.column("name", .text).notNull()
        t.column("device_id", .integer).notNull()
        t.column("identity", .blob)
        t.primaryKey(["name", "device_id"])
      }

      try db.create(table: "session_store") { t in
        t.column("name", .text).notNull()
        t.column("device_id", .integer).notNull()
        t.column("session", .blob).notNull()
        t.column("user_record", .blob)
        t.primaryKey(["name", "device_id"])
      }
    }

    migrator.registerMigration("create_messages") { db in
      try db.create(table: "messages") { t in
        t.column("id", .integer).primaryKey()
        t.column("author_name", .text).notNull().indexed()
        t.column("author_device_id", .integer).notNull()
        t.column("body", .text).notNull()
        t.foreignKey(["author_name", "author_device_id"],
                     references: "identity_key_store",
                     onDelete: .cascade,
                     onUpdate: .restrict)
      }
    }

    return migrator
  }
}

#if DEBUG
extension AppDatabase {
  static func drop() throws {
    let url = try FileManager.default
      .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      .appendingPathComponent("db.sqlite")

    try FileManager.default.removeItem(atPath: url.path)
  }
}
#endif
