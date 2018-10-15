import XCTest
@testable import almost_secure
import SignalProtocol
import Birdsong

class RemoteSearchServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()

    let _setUp = XCTestExpectation(description: "set up")

    Backend.cleanStorage()
      .then { Backend.createAddress(name: "alice") }
      .catch { error in fatalError("failed to setup with error: \(error)") }
      .always { _setUp.fulfill() }

    wait(for: [_setUp], timeout: 5.0)
  }

  func testSearch() {
    let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": "bob"])

    let expected = [
      SignalAddress(name: "alice", deviceId: 1)
    ]

    // connect

    let connectExpectation = XCTestExpectation(description: "socketConnect")
    socket.onConnect = { connectExpectation.fulfill() }
    socket.connect()
    wait(for: [connectExpectation], timeout: 10.0)

    // actually test

    let serviceExpectation = XCTestExpectation(description: "listRecent")

    let service = SearchService(channel: SearchChannel(channel: socket.channel(AppChannels.search)))

    service.start()
      .then { service.search(for: "alice") }
      .then { addresses in
        XCTAssertEqual(expected.count, addresses.count)
        XCTAssertEqual(expected[0], addresses[0])
      }
      .catch { error in XCTFail("failed search with error: \(error)") }
      .always { serviceExpectation.fulfill() }

    wait(for: [serviceExpectation], timeout: 10.0)
  }
}
