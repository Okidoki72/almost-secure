import Birdsong
import SignalProtocol
import Promises

final class SearchChannel {
  enum Error: Swift.Error {
    case invalidResponse(Socket.Payload)
  }

  private let channel: Channel

  init(channel: Channel) {
    self.channel = channel
  }

  deinit {
    leave()
  }

  func join() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    channel.join()?.receive("ok") { _ in promise.fulfill(()) }
    return promise
  }

  @discardableResult
  func leave() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    channel.leave()?.receive("ok") { _ in promise.fulfill(()) }
    return promise
  }

  func search(query: String) -> Promise<[SignalAddress]> {
    let promise = Promise<[SignalAddress]>.pending()

    channel.send("search", payload: ["query": query])?.receive("ok") { payload in
      guard
        let response = payload["response"] as? [String: Any],
        let users = response["users"] as? [[String: String]] else {
          promise.reject(Error.invalidResponse(payload))
          return
      }

      let addresses = users.map { user in
        SignalAddress(name: user["name"]!, deviceId: 1)
      }

      promise.fulfill(addresses)
    }

    return promise
  }
}
