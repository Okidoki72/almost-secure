import XCTest
@testable import almost_secure
import Birdsong
import SignalProtocol

class SearchChannelTests: XCTestCase {
  override func setUp() {
    super.setUp()

    let _setUp = XCTestExpectation(description: "set up")
    Backend.cleanStorage()
      .then { Backend.createAddress(name: "bob") }
      .then { _setUp.fulfill() }
      .catch { error in fatalError("\(error)") }

    wait(for: [_setUp], timeout: 5.0)
  }

  func testSearch() {
    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "alice"])

    let _connect = XCTestExpectation(description: "connect")
    socket.onConnect = { _connect.fulfill() }
    socket.connect()
    wait(for: [_connect], timeout: 3.0)

    let channel = SearchChannel(channel: socket.channel(AppChannels.search))
    let expected = [SignalAddress(name: "bob", deviceId: 1)]

    let _search = XCTestExpectation(description: "search")
    channel.join()
      .then { channel.search(query: "bob") }
      .then { addresses in XCTAssertEqual(addresses, expected) }
      .always { _search.fulfill() }

    wait(for: [_search], timeout: 3.0)
  }
}
