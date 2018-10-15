import XCTest
@testable import almost_secure
import SignalProtocol
import GRDBCipher
import Birdsong

class RemoteUserServiceTests: XCTestCase {
  var dbQueue: DatabaseQueue!

  override func setUp() {
    super.setUp()
    dbQueue = try! AppDatabase.open(.temp, passphrase: "yay")
  }

  /// in this one alice will hear that bob wants to talk with her
  func testOnNewChat() {
    let aliceAddress = SignalAddress(name: "alice", deviceId: 1)
    let bobAddress = SignalAddress(name: "bob", deviceId: 1)

    let aliceConnectExpectation = XCTestExpectation(description: "alice socketConnect")
    let bobConnectExpectation = XCTestExpectation(description: "bob socketConnect")

    let aliceSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": aliceAddress.name])
    aliceSocket.onConnect = { aliceConnectExpectation.fulfill() }
    aliceSocket.connect()

    let bobSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": bobAddress.name])
    bobSocket.onConnect = { bobConnectExpectation.fulfill() }
    bobSocket.connect()

    wait(for: [aliceConnectExpectation, bobConnectExpectation], timeout: 5.0)

    let onNewChatExpectation = XCTestExpectation(description: "onNewChat")

    let aliceService = UserService(dbQueue: dbQueue,
                                   channel: UserChannel(channel: aliceSocket.channel(AppChannels.user(name: aliceAddress.name))),
                                   onNewChat: { address in
                                    XCTAssertEqual(address, bobAddress)
                                    onNewChatExpectation.fulfill() })
    aliceService.start().then {
      bobSocket.channel(AppChannels.chat(names: [aliceAddress.name, bobAddress.name])).join()
    }

    wait(for: [onNewChatExpectation], timeout: 5.0)
  }
}
