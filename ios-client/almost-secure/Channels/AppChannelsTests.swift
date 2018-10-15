import XCTest
@testable import almost_secure

class AppChannelsTests: XCTestCase {
  func testToPreventUnexpectedChanges() {
    XCTAssertEqual(AppChannels.user(name: "alice"), "user:alice")
    XCTAssertEqual(AppChannels.search, "search")
    XCTAssertEqual(AppChannels.chat(names: ["bob", "alice"]), "chats:alice:bob")
    XCTAssertEqual(AppChannels.chat(names: ["alice", "bob"]), "chats:alice:bob")
  }
}
