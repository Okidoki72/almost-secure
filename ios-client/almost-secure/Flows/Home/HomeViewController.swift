import UIKit
import Reusable
import SignalProtocol

final class HomeViewController: UIViewController, StoryboardBased {
  var onAdd: (() -> Void)?
  var onChatSelect: ((SignalAddress) -> Void)?
  var chats = [RecentChat]()

  private static let cellID = "RecentChatCell"

  @IBOutlet weak var chatsTableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chats"
    
    chatsTableView.dataSource = self
    chatsTableView.delegate = self

    // TODO do this in storyboard?
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                       target: self,
                                                       action: #selector(addTapped))
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // TODO update last messages, chats
  }

  @objc private func addTapped() {
    onAdd?()
  }

  func addChat(_ address: SignalAddress) {
    let chat = RecentChat(address: address, lastMessage: nil)
    chats.insert(chat, at: 0)
    chatsTableView.beginUpdates()
    chatsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    chatsTableView.endUpdates()
  }
}

extension HomeViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return chats.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: HomeViewController.cellID, for: indexPath)
    (cell as? RecentChatCell)?.configure(with: chats[indexPath.row])
    return cell
  }
}

extension HomeViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onChatSelect?(chats[indexPath.row].address)
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
