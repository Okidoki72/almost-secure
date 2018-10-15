import XCTest
@testable import almost_secure
import SignalProtocol
import GRDBCipher
import Birdsong

class UserServiceTests: XCTestCase {
  var dbQueue: DatabaseQueue!

  override func setUp() {
    super.setUp()
    dbQueue = try! AppDatabase.open(.temp, passphrase: "yay")
  }

  func testListRecent() {
    let service = UserService(dbQueue: dbQueue,
                              channel: UserChannel(channel: Socket(url: "").channel("")),
                              onNewChat: { _ in })

    let _list = XCTestExpectation(description: "listRecent")

    // dummy data
    try! dbQueue.write { db in
      try db.execute("INSERT INTO identity_key_store (name, device_id) VALUES (?, 1)", arguments: ["alice"])
      try db.execute("INSERT INTO identity_key_store (name, device_id) VALUES (?, 1)", arguments: ["bob"])
      try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: ["hello 1", "alice"])
      try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: ["hello 1", "bob"])
      try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: ["hello 2", "alice"])
      try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: ["hello 2", "bob"])
      try db.execute("INSERT INTO messages (body, author_name, author_device_id) VALUES (?, ?, 1)", arguments: ["hello 3", "alice"])
    }

    let bob = SignalAddress(name: "bob", deviceId: 1)
    let alice = SignalAddress(name: "alice", deviceId: 1)

    let expected: [RecentChat] = [
      (address: alice, lastMessage: Message(body: "hello 3", author: alice)),
      (address: bob, lastMessage: Message(body: "hello 2", author: bob)),
    ]

    service.listRecent().then { recents in
      XCTAssertEqual(recents[0].address, expected[0].address)
      XCTAssertEqual(recents[0].lastMessage!.body, expected[0].lastMessage!.body)
      XCTAssertEqual(recents[1].address, expected[1].address)
      XCTAssertEqual(recents[1].lastMessage!.body, expected[1].lastMessage!.body)
      _list.fulfill()
    }.catch { error in
      XCTFail("failed with error: \(error)")
    }

    wait(for: [_list], timeout: 10.0)
  }
}
