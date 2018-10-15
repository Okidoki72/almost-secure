import Birdsong
import Promises
import SignalProtocol

final class ChatChannel {
  enum Event {
    case newMessage(Data)
  }

  enum Error: Swift.Error {
    case channelError(Socket.Payload)
  }

  typealias Subscription = (Event) -> Void

  private let channel: Channel
  private var subscriptions = [Subscription]()

  init(channel: Channel) {
    self.channel = channel
    channel.on("new:message") { [weak self] response in
      guard let self = self else { return }
      let data = Data(base64Encoded: response.payload["data"] as! String)!
      for subscription in self.subscriptions {
        subscription(.newMessage(data))
      }
    }
  }

  deinit {
    leave()
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

  func send(_ data: Data) -> Promise<Void> {
    let promise = Promise<Void>.pending()

    channel
      .send("new:message", payload: ["data": data.base64EncodedString()])?
      .receive("ok") { payload in promise.fulfill(()) }
      .receive("error") { payload in promise.reject(Error.channelError(payload)) }

    return promise
  }

  func subscribe(with subscription: @escaping Subscription) {
    subscriptions.append(subscription)
  }
}
