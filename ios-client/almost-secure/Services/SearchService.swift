import Birdsong
import SignalProtocol
import Promises

// TODO need it?
protocol SearchServiceType {
  func search(for query: String) -> Promise<[SignalAddress]>
  //    func sessionPreKeyBundle(for address: SignalAddress) -> Promise<SessionPreKeyBundle?>
}


// TODO need it?
final class SearchService: SearchServiceType {
  enum Error: Swift.Error {
    case channelError(Socket.Payload)
    case invalidResponse(Socket.Payload)
  }
  
  private let channel: SearchChannel
  
  init(channel: SearchChannel) {
    self.channel = channel
  }
  
  func start() -> Promise<Void> {
    return channel.join()
  }
  
  func search(for query: String) -> Promise<[SignalAddress]> {
    return channel.search(query: query)
  }
  
  // TODO wtf is it doing here?
  //  func sessionPreKeyBundle(for address: SignalAddress) -> Promise<SessionPreKeyBundle?> {
  //    let payload = ["address": ["name": address.name, "device_id": address.deviceId]]
  //    channel.send("sessionPreKeyBundle", payload: payload)?
  //      .receive("ok") { _ in }
  //      .receive("error") { _ in }
  //  }
}
