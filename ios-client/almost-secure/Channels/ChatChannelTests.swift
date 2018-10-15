import XCTest
@testable import almost_secure
import SignalProtocol
import Birdsong

class ChatChannelTests: XCTestCase {
  func testSendReceive() {
    let _aliceConnect = XCTestExpectation(description: "alice connect")
    let _bobConnect = XCTestExpectation(description: "bob connect")

    let aliceSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "alice"])
    let bobSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "bob"])

    aliceSocket.onConnect = { _aliceConnect.fulfill() }
    bobSocket.onConnect = { _bobConnect.fulfill() }

    aliceSocket.connect()
    bobSocket.connect()

    wait(for: [_aliceConnect, _bobConnect], timeout: 3.0)

    let aliceChannel = ChatChannel(channel: aliceSocket.channel(AppChannels.chat(names: ["alice", "bob"])))
    let bobChannel = ChatChannel(channel: bobSocket.channel(AppChannels.chat(names: ["alice", "bob"])))

    var bobMailbox: [String] = []
    var aliceMailbox: [String] = []

    _ = aliceChannel.join()
    _ = bobChannel.join()

    let _alice = XCTestExpectation(description: "alice messages")
    aliceChannel.subscribe { event in
      switch event {
      case let .newMessage(data):
        aliceMailbox.append(String(data: data, encoding: .utf8)!)
      }

      if aliceMailbox.count == 3 {
        XCTAssertEqual(aliceMailbox, ["hello alice", "howdy doody", "metoo"])
        _alice.fulfill()
      }
    }

    let _bob = XCTestExpectation(description: "bob messages")
    bobChannel.subscribe { event in
      switch event {
      case let .newMessage(data):
        bobMailbox.append(String(data: data, encoding: .utf8)!)
      }

      if bobMailbox.count == 2 {
        XCTAssertEqual(bobMailbox, ["hello bob", "pretty goody, you?"])
        _bob.fulfill()
      }
    }

    _ = bobChannel.send("hello alice".data(using: .utf8)!)
    _ = aliceChannel.send("hello bob".data(using: .utf8)!)
    _ = bobChannel.send("howdy doody".data(using: .utf8)!)
    _ = aliceChannel.send("pretty goody, you?".data(using: .utf8)!)
    _ = bobChannel.send("metoo".data(using: .utf8)!)

    wait(for: [_alice, _bob], timeout: 8.0)
  }
}
