import UIKit

final class Router: Presentable {
  private weak var rootController: UINavigationController?
  private var completions = [UIViewController: () -> Void]()

  init(rootController: UINavigationController) {
    self.rootController = rootController
  }

  func setDelegate(to delegate: UINavigationControllerDelegate) {
    rootController?.delegate = delegate
  }

  func toPresent() -> UIViewController? {
    return rootController
  }

  func present(_ module: Presentable?, animated: Bool = true) {
    guard let controller = module?.toPresent() else { return }
    rootController?.present(controller, animated: animated)
  }

  func push(_ module: Presentable?, animated: Bool = true, completion: (() -> Void)? = nil) {
    guard let controller = module?.toPresent(), !(controller is UINavigationController) else {
      assertionFailure("Deprecated push UINavigationController.")
      return
    }

    if let completion = completion { completions[controller] = completion }

    rootController?.pushViewController(controller, animated: animated)
  }

  func popModule(animated: Bool = true) {
    if let controller = rootController?.popViewController(animated: animated) {
      runCompletion(for: controller)
    }
  }

  func dismissModule(animated: Bool = true, completion: (() -> Void)? = nil) {
    rootController?.dismiss(animated: animated, completion: completion)
  }

  func setRoot(to module: Presentable?, hideBar: Bool = false) {
    guard let controller = module?.toPresent() else { return }
    rootController?.setViewControllers([controller], animated: false)
    rootController?.isNavigationBarHidden = hideBar
  }

  func popToRootModule(animated: Bool = true) {
    if let controllers = rootController?.popToRootViewController(animated: animated) {
      controllers.forEach(runCompletion)
    }
  }

  private func runCompletion(for controller: UIViewController) {
    if let completion = completions.removeValue(forKey: controller) {
      completion()
    }
  }
}
