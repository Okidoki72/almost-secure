import UIKit
import SignalProtocol

final class SearchAddressCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!

  func configure(with address: SignalAddress) {
    nameLabel.text = address.name
  }
}
