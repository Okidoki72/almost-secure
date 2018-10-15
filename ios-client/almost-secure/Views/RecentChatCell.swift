import UIKit

private let niceColors: [UIColor] = [
  #colorLiteral(red: 0.8837939664, green: 0.9646985833, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.9072752695, blue: 0.9024511554, alpha: 1), #colorLiteral(red: 0.8855633727, green: 1, blue: 0.8306912362, alpha: 1)
]

final class RecentChatCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var lastMessageLabel: UILabel!

  func configure(with recentChat: RecentChat) {
    nameLabel.text = recentChat.address.name
    lastMessageLabel.text = recentChat.lastMessage?.body
    backgroundColor = niceColors.randomElement()!
  }
}
