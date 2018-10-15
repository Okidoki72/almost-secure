import XCTest
@testable import almost_secure

class HTTPTests: XCTestCase {
  // sanity check
  func testRequestJSONEncoding() {
    let request = try! HTTP.request(.post, path: "/", body: ["name": "alice"])
    XCTAssertEqual(String(data: request.httpBody!, encoding: .utf8)!, "{\"name\":\"alice\"}")
    XCTAssertEqual(request.allHTTPHeaderFields, ["Content-Type": "application/json"])
  }
}
