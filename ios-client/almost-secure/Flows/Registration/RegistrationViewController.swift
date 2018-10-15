import UIKit
import Reusable

final class RegistrationViewController: UIViewController, StoryboardBased {
  @IBOutlet private weak var nameField: UITextField!
  @IBOutlet private weak var errorMessageLabel: UILabel!

  private enum NameInputError: String {
    case empty = "Can't be empty!"
  }

  private var error: NameInputError? {
    didSet {
      if let error = error {
        errorMessageLabel.text = error.rawValue
        errorMessageLabel.isHidden = false
      } else {
        errorMessageLabel.text = nil
        errorMessageLabel.isHidden = true
      }
    }
  }

  var onSubmit: ((String) -> Void)?
  var status: AccountService.Status = .idle {
    didSet {
      switch status {
      case .busy: UIApplication.shared.isNetworkActivityIndicatorVisible = true
      case .idle: UIApplication.shared.isNetworkActivityIndicatorVisible = false
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    nameField.delegate = self
    nameField.addTarget(self, action: #selector(onEditingChanged), for: .editingChanged)
  }

  @objc private func onEditingChanged(_ sender: UITextField) {
    let name = sender.text!.trimmingCharacters(in: .whitespacesAndNewlines)
    error = name.isEmpty ? .empty : nil
  }
}

extension RegistrationViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard error == nil, status != .busy else { return false }
    onSubmit?(textField.text!)
    return true
  }
}
