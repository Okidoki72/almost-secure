import Foundation

protocol Coordinating: class {
  func start()
}

class BaseCoordinator: NSObject, Coordinating {
  private var childCoordinators = [Coordinating]()

  func start() {}

  func add(childCoordinator: Coordinating) {
    for element in childCoordinators {
      if element === childCoordinator {
        return
      }
    }
    childCoordinators.append(childCoordinator)
  }

  func remove(childCoordinator: Coordinating?) {
    guard let childCoordinator = childCoordinator, !childCoordinators.isEmpty else { return }
    childCoordinators = childCoordinators.filter { $0 !== childCoordinator }
  }

  func remove(closure: (Coordinating) -> Bool) {
    childCoordinators = childCoordinators.filter { !closure($0) }
  }
}
