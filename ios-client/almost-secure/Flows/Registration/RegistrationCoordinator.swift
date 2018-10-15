final class RegistrationCoordinator: BaseCoordinator {
  private let router: Router

  init(router: Router) {
    self.router = router
  }

  var onSuccess: (() -> Void)?

  override func start() {
    showRegistration()
  }

  private func showRegistration() {
    let vc = RegistrationViewController.instantiate()
    vc.onSubmit = { [unowned self] name in
      AccountService.register(name: name)
        .then { _ in self.onSuccess?() }
        .catch { error in fatalError("error: \(error)") } // TODO self.show(error: error)
        .always { vc.status = .idle }

      vc.status = .busy
    }
    router.setRoot(to: vc, hideBar: true)
  }
}
