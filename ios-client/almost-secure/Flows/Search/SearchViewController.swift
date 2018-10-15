import UIKit
import Reusable
import SignalProtocol

final class SearchViewController: UIViewController, StoryboardBased {
  private static let cellID = "SearchAddressCell"

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!

  var onInput: ((String) -> Void)?
  var onAddressSelect: ((SignalAddress) -> Void)?

  var foundAddresses: [SignalAddress] = [] {
    didSet {
      if foundAddresses != oldValue {
        tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search"
    tableView.delegate = self
    tableView.dataSource = self
    searchBar.delegate = self
    searchBar.autocapitalizationType = .none
  }
}

extension SearchViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    onInput?(searchText)
  }
}

extension SearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return foundAddresses.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: SearchViewController.cellID, for: indexPath)
    (cell as? SearchAddressCell)?.configure(with: foundAddresses[indexPath.row])
    return cell
  }
}

extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onAddressSelect?(foundAddresses[indexPath.row])
  }
}
