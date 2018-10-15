import SignalProtocol
import Birdsong
import Promises

final class UserChannel {
  enum Event {
    case chatStarted(with: SignalAddress)
  }

  enum Error: Swift.Error {
    case channelError(Socket.Payload)
  }

  typealias Subscription = (Event) -> Void

  private let channel: Channel
  private var subscriptions = [Subscription]()

  init(channel: Channel) {
    self.channel = channel
    channel.on("chat:started") { [weak self] response in
      guard let self = self else { return }
      let name = response.payload["with"] as! String
      let address = SignalAddress(name: name, deviceId: 1)
      for subscription in self.subscriptions {
        subscription(.chatStarted(with: address))
      }
    }
  }

  func join() -> Promise<Void> {
    let promise = Promise<Void>.pending()

    channel.join()?
      .receive("ok") { _ in promise.fulfill(()) }
      .receive("error") { payload in promise.reject(Error.channelError(payload)) }

    return promise
  }

  @discardableResult
  func leave() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    channel.leave()?.receive("ok") { _ in promise.fulfill(()) }
    return promise
  }

  deinit {
    leave()
  }

  func add(subscription: @escaping Subscription) {
    subscriptions.append(subscription)
  }
}
