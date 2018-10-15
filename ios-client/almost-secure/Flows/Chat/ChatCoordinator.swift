import GRDBCipher
import SignalProtocol
import Birdsong

final class ChatCoordinator: BaseCoordinator {
  private let account: AppAccount
  private let dbQueue: DatabaseQueue
  private let socket: Socket
  private let router: Router
  private let address: SignalAddress

  var onFinish: (() -> Void)?

  init(account: AppAccount,
       dbQueue: DatabaseQueue,
       socket: Socket,
       router: Router,
       address: SignalAddress) {
    self.account = account
    self.dbQueue = dbQueue
    self.address = address
    self.socket = socket
    self.router = router
  }

  override func start() {
    showChat()
  }

  private func showChat() {
    let vc = ChatViewController(ourAddress: account.address)
    let store = try! account.store(dbQueue: dbQueue)
    let channelName = AppChannels.chat(names: [account.address.name, address.name])
    let onNewMessage = { (body: String) in
      let message = Message(body: body, author: self.address)
      vc.didReceiveNewMessage(message)
    }

    // ChatService / SessionService
    //   .session(for: address) // fetches from localstore or from network
    //   .then { }
    //   .catch()

    if store.sessionStore.containsSession(for: address) {

      let channel = ChatChannel(channel: socket.channel(channelName))
      let messageService = MessageService(channel: channel,
                                          cipher: SessionCipher(for: address, in: store),
                                          onNewMessage: onNewMessage)

      vc.onSend = { message in
        messageService.send(message).catch { error in
          fatalError("failed to send a message with error: \(error)")
        }
      }

      router.push(vc)
    } else {
      AccountService.preKeyBundle(for: address)
        .then { [weak self] preKeyBundle in
          guard let `self` = self else { return }
          let sessionPreKeyBundle = SessionPreKeyBundle(registrationId: preKeyBundle.registrationId,
                                                        deviceId: 1,
                                                        preKeyId: preKeyBundle.preKey.id,
                                                        preKey: preKeyBundle.preKey.publicKey,
                                                        signedPreKeyId: preKeyBundle.signedPreKey.id,
                                                        signedPreKey: preKeyBundle.signedPreKey.publicKey,
                                                        signature: preKeyBundle.signedPreKey.signature,
                                                        identityKey: preKeyBundle.identityKey)

          try! SessionBuilder(for: self.address, in: store).process(preKeyBundle: sessionPreKeyBundle)
          let channel = ChatChannel(channel: self.socket.channel(channelName))
          let messageService = MessageService(channel: channel,
                                              cipher: SessionCipher(for: self.address, in: store),
                                              onNewMessage: onNewMessage)

          vc.onSend = { message in
            messageService.send(message).catch { error in
              fatalError("failed to send a message with error: \(error)")
            }
          }

          self.router.push(vc)
        }
        .catch { error in fatalError("failed with error: \(error)") }
    }
  }
}
