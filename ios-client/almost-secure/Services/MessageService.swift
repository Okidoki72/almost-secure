import Result
import Birdsong
import SignalProtocol
import Promises

final class MessageService {
  private let channel: ChatChannel
  private let cipher: SessionCipher

  enum Error: Swift.Error {
    case encodingError
    case encryptionError(SignalError)
    case channelError(Socket.Payload)
  }

  init(channel: ChatChannel,
       cipher: SessionCipher,
       onNewMessage: @escaping (String) -> Void) {
    self.cipher = cipher
    self.channel = channel

    channel.subscribe { event in
      switch event {
      case let .newMessage(data):
        let cipherText = CiphertextMessage(from: data)
        let messageBody = String(data: try! cipher.decrypt(message: cipherText), encoding: .utf8)!
        onNewMessage(messageBody)
      }
    }
  }

  func start() -> Promise<Void> {
    return channel.join()
  }

  // TODO two promises?
  func send(_ message: String) -> Promise<Void> {
    let promise = Promise<Void>.pending()

    guard let data = message.data(using: .utf8) else {
      promise.reject(Error.encodingError)
      return promise
    }

    let cipherText: CiphertextMessage
    do {
      cipherText = try cipher.encrypt(data)
    } catch let error as SignalError {
      promise.reject(Error.encryptionError(error))
      return promise
    } catch {
      fatalError("Unexpected error: \(error)")
    }

    channel.send(cipherText.data).then {
      promise.fulfill(())
    }

    return promise
  }
}
