import XCTest
@testable import almost_secure
import Promises
import Birdsong
import SignalProtocol

class UserChannelTests: XCTestCase {
  func testJoinWithValidCreds() {
    let _connect = XCTestExpectation(description: "connect")
    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "alice"])
    socket.onConnect = { _connect.fulfill() }
    socket.connect()
    wait(for: [_connect], timeout: 3.0)

    let channel = UserChannel(channel: socket.channel(AppChannels.user(name: "alice")))

    let _join = XCTestExpectation(description: "join")
    channel.join().then { _join.fulfill() }
    wait(for: [_join], timeout: 3.0)
  }

//  func testJoinWithInvalidCreds() {
//    let _connect = XCTestExpectation(description: "connect")
//    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "eve"])
//    socket.onConnect = { _connect.fulfill() }
//    socket.connect()
//    wait(for: [_connect], timeout: 3.0)
//
//    let channel = UserChannel(channel: socket.channel(AppChannels.user(name: "alice")))
//
//    let _join = XCTestExpectation(description: "join")
//    channel.join()
//      .catch { error in
//        switch error {
//        case let UserChannel.Error.channelError(payload):
//          let expected = [String: Any]()
//          let response = payload["response"] as! [String: Any]
//          XCTAssertEqual(response, expected)
//        default:
//          XCTFail("unexpected error: \(error)")
//        }
//      }
//      .always { _join.fulfill() }
//
//    wait(for: [_join], timeout: 3.0)
//  }

  func testLeave() {
    let _connect = XCTestExpectation(description: "connect")
    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "alice"])
    socket.onConnect = { _connect.fulfill() }
    socket.connect()
    wait(for: [_connect], timeout: 3.0)

    let channel = UserChannel(channel: socket.channel(AppChannels.user(name: "alice")))

    let _leave = XCTestExpectation(description: "leave")
    channel.join()
      .then { channel.leave() }
      .then { _leave.fulfill() }

    wait(for: [_leave], timeout: 3.0)
  }

  func testChatStartedSubscription() {
    let _connect = XCTestExpectation(description: "connect")
    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "alice"])
    socket.onConnect = { _connect.fulfill() }
    socket.connect()
    wait(for: [_connect], timeout: 3.0)

    let channel = UserChannel(channel: socket.channel(AppChannels.user(name: "alice")))

    let expectedAddress = SignalAddress(name: "bob", deviceId: 1)

    let _event = XCTestExpectation(description: "event")

    _ = channel.join()
    channel.add { event in
      switch event {
      case let .chatStarted(with: address):
        XCTAssertEqual(address, expectedAddress)
        _event.fulfill()
      }
    }

    let bobSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "bob"])
    bobSocket.onConnect = {
      bobSocket.channel(AppChannels.chat(names: ["alice", "bob"])).join()
    }

    bobSocket.connect()
    
    wait(for: [_event], timeout: 3.0)
  }
}
