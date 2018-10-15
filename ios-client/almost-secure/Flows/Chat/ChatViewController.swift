import UIKit
import SignalProtocol
import MessageKit
import MessageInputBar

// MARK: -
final class ChatViewController: MessagesViewController {
  private var messages: [Message] = [
    .init(body: "Hello", author: .init(name: "alice", deviceId: 1)),
    .init(body: "Hello", author: .init(name: "bob", deviceId: 1)),
    .init(body: "How are you?", author: .init(name: "alice", deviceId: 1)),
    .init(body: "Fine", author: .init(name: "bob", deviceId: 1)),
    .init(body: "Ok", author: .init(name: "alice", deviceId: 1)),
    .init(body: "I'm fine too", author: .init(name: "alice", deviceId: 1)),
    .init(body: "jk", author: .init(name: "alice", deviceId: 1)),
    .init(body: "???", author: .init(name: "bob", deviceId: 1)),
    .init(body: "what happnd", author: .init(name: "bob", deviceId: 1)),
    .init(body: "my cat died", author: .init(name: "alice", deviceId: 1)),
    .init(body: "omg", author: .init(name: "bob", deviceId: 1)),
    .init(body: "yeah", author: .init(name: "alice", deviceId: 1)),
    .init(body: "i'm so sorry", author: .init(name: "bob", deviceId: 1)),
    .init(body: "as you should be!\n\ni shouldn't have let you near it .....", author: .init(name: "alice", deviceId: 1))
  ]

  private let ourAddress: SignalAddress
  var onSend: ((String) -> Void)? // TODO

  init(ourAddress: SignalAddress) {
    self.ourAddress = ourAddress
//    self.onSend = onSend
    super.init(nibName: nil, bundle: nil)
  }

  @available (*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func insertNewMessage(_ message: Message) {
    messages.append(message)
    // TODO
    messagesCollectionView.reloadData()

    // TODO maybe use a rotated tablview instead

//    messagesCollectionView.beginUpdates()
//    messagesCollectionView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)],
//    //                                with: .automatic)
//    //    chatTableView.endUpdates()

    DispatchQueue.main.async {
      self.messagesCollectionView.scrollToBottom(animated: true)
    }
  }
}

// MARK: - view controller lifecycle
extension ChatViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 11.0, *) {
      navigationItem.largeTitleDisplayMode = .never
    }

    maintainPositionOnKeyboardFrameChanged = true
    //    messageInputBar.inputTextView.tintColor = .black
    //    messageInputBar.sendButton.setTitleColor(.cyan, for: .normal)

    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self

    setupCollectionView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    messagesCollectionView.scrollToBottom(animated: true)
  }
}

// MARK: - MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else { return }
    onSend?(trimmedText)
    insertNewMessage(Message(body: trimmedText, author: ourAddress))
    inputBar.inputTextView.text = ""
  }

  func markAsSent(_ messageID: Int) {
    // TODO
  }
}

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
  func currentSender() -> Sender {
    return Sender(id: ourAddress.name, displayName: ourAddress.name)
  }

  func messageForItem(at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
  }

  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
  func avatarSize(for message: MessageType,
                  at indexPath: IndexPath,
                  in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .zero
  }

  func footerViewSize(for section: Int,
                      in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .init(width: 0, height: 6)
  }

  func heightForLocation(message: MessageType,
                         at indexPath: IndexPath,
                         with maxWidth: CGFloat,
                         in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 0
  }

  private func setupCollectionView() {
    guard
      let flowLayout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout else {
        return
    }

    flowLayout.textMessageSizeCalculator.outgoingAvatarSize = .zero
    flowLayout.textMessageSizeCalculator.incomingAvatarSize = .zero
    flowLayout.attributedTextMessageSizeCalculator.outgoingAvatarSize = .zero
    flowLayout.attributedTextMessageSizeCalculator.incomingAvatarSize = .zero
  }
}

// MARK: - MessagesDisplayDelegate
private let niceBlue = #colorLiteral(red: 0.5570799411, green: 0.6464388335, blue: 0.9764705896, alpha: 1)
private let nicePink = #colorLiteral(red: 0.9098039269, green: 0.7969884535, blue: 0.8917113653, alpha: 1)

extension ChatViewController: MessagesDisplayDelegate {
  func backgroundColor(for message: MessageType,
                       at indexPath: IndexPath,
                       in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? niceBlue : nicePink
  }

  func messageStyle(for message: MessageType,
                    at indexPath: IndexPath,
                    in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message)
      ? .bottomRight
      : .bottomLeft

    return .bubbleTail(corner, .pointedEdge)
  }
}

// MARK: - when a new message is received from the other user
extension ChatViewController {
  func didReceiveNewMessage(_ message: Message) {
    insertNewMessage(message)
  }
}
