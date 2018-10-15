import Result
import SignalProtocol
import GRDBCipher
import Birdsong
import Promises

typealias RecentChat = (address: SignalAddress, lastMessage: Message?)

protocol UserServiceType {
  func listRecent() -> Promise<[RecentChat]>
}

final class UserService: UserServiceType {
  enum Error: Swift.Error {
    case dbError(Swift.Error)
  }

  private let dbQueue: DatabaseQueue
  private let channel: UserChannel

  init(dbQueue: DatabaseQueue, channel: UserChannel, onNewChat: @escaping (SignalAddress) -> Void) {
    self.dbQueue = dbQueue
    self.channel = channel
    channel.add { event in
      switch event {
      case let .chatStarted(with: address):
        onNewChat(address)
      }
    }
  }

  func start() -> Promise<Void> {
    return channel.join()
  }

  func listRecent() -> Promise<[RecentChat]> {
    return Promise<[RecentChat]> { fulfill, reject in
      let recents = try self.dbQueue.read { db -> [RecentChat] in
        let sql = """
        SELECT i.name, i.device_id, m.body
        FROM identity_key_store AS i
        LEFT JOIN messages AS m ON m.id = (
          SELECT id
          FROM messages AS m
          WHERE
            i.name = m.author_name AND
            i.device_id = m.author_device_id
          ORDER BY m.id DESC
          LIMIT 1
        );
        """

        return try Row.fetchAll(db, sql).map {
          let address = SignalAddress(name: $0["name"], deviceId: $0["device_id"])
          let messageBody: String? = $0["body"]
          let lastMessage: Message
          if let messageBody = messageBody {
            lastMessage = Message(body: messageBody, author: address)
          } else {
            lastMessage = Message(body: "wtf you are about", author: address)
          }
          return (address: address, lastMessage: lastMessage)
        }
      }

      fulfill(recents)
    }
  }
}

#if DEBUG
extension UserService {
  func addRecent(name: String, messages: [String]) {
    try! dbQueue.write { db in
      try db.execute("INSERT INTO identity_key_store (name, device_id) VALUES (?, 1)", arguments: [name])
      try messages.forEach {
        try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: [$0, name])
      }
    }
  }

  func removeRecent(name: String) {
    try! dbQueue.write { db in
      try db.execute("DELETE FROM identity_key_store WHERE name = ? AND device_id = 1", arguments: [name])
    }
  }
}
#endif
