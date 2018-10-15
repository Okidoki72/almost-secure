import Foundation
import SignalProtocol
import MessageKit

struct Message {
  let id: Int
  let body: String
  let date: Date
  let author: SignalAddress

  private static var _id: Int = 1
}

extension Message: Equatable {
  static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id
  }
}

extension Message {
  init(body: String, author: SignalAddress, date: Date = Date()) {
    self.id = Message._id
    Message._id += 1
    self.body = body
    self.author = author
    self.date = date
  }
}

extension Message: MessageType {
  var sender: Sender {
    return .init(id: author.name, displayName: author.name)
  }

  var messageId: String {
    return String(id)
  }

  var sentDate: Date {
    return date
  }

  var kind: MessageKind {
    return .text(body)
  }
}
