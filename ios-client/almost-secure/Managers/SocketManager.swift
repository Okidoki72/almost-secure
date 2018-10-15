import Birdsong
import SignalProtocol
import Promises

final class SocketManager {
  private let socket: Socket

  //  private var channels: Set<Channel> = []
  private var _userChannel: UserChannel?
  private var _searchChannel: SearchChannel?
  private var _chatChannel: ChatChannel?

  func userChannel(for address: SignalAddress) -> UserChannel {
    if let userChannel = _userChannel {
      return userChannel
    } else {
      let channel = socket.channel(AppChannels.user(name: address.name))
      let userChannel = UserChannel(channel: channel)
      _userChannel = userChannel
      return userChannel
    }
  }

  var searchChannel: SearchChannel {
    if let searchChannel = _searchChannel {
      return searchChannel
    } else {
      let channel = socket.channel(AppChannels.search)
      let searchChannel = SearchChannel(channel: channel)
      _searchChannel = searchChannel
      return searchChannel
    }
  }

  func chatChannel(for names: [String]) -> ChatChannel {
    if let chatChannel = _chatChannel {
      return chatChannel
    } else {
      let channel = socket.channel(AppChannels.chat(names: names))
      let chatChannel = ChatChannel(channel: channel)
      _chatChannel = chatChannel
      return chatChannel
    }
  }

  private static var _default: SocketManager?

  static func `default`(address: SignalAddress) -> SocketManager {
    if let _default = SocketManager._default {
      return _default
    } else {
      let socket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": address.name])
      let manager = SocketManager(socket: socket)
      SocketManager._default = manager
      return manager
    }
  }

  init(socket: Socket) {
    socket.onDisconnect = { error in
      if let error = error {
        fatalError("\(error)") // TODO
      }

      // try to reconnect
    }

    self.socket = socket
  }

  func connect() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    socket.onConnect = { promise.fulfill(()) }
    socket.connect()
    return promise
  }
}
