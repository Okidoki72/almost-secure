import GRDBCipher
import SignalProtocol
import Birdsong

final class HomeCoordinator: BaseCoordinator {
  private let account: AppAccount
  private let dbQueue: DatabaseQueue
  private let router: Router
  private let socket: Socket
  private var userService: UserService?
  private let userChannel: UserChannel

  init(account: AppAccount, dbQueue: DatabaseQueue, router: Router) {
    self.account = account
    self.dbQueue = dbQueue
    self.router = router
    let socket = Socket(url: "http://192.168.1.44:4000/socket/websocket", params: ["name": account.address.name])
    let userChannel = UserChannel(channel: socket.channel(AppChannels.user(name: account.address.name)))
    socket.onConnect = { _ = userChannel.join() }
    socket.connect() // TODO
    self.socket = socket
    self.userChannel = userChannel
  }

  override func start() {
    showRecent()
    router.setDelegate(to: self)
  }

  private func showRecent() {
    let vc = HomeViewController.instantiate()

    let service = UserService(dbQueue: dbQueue,
                              channel: userChannel,
                              onNewChat: { [weak vc] address in vc?.addChat(address) })

    // TODO show loading indicator?
    service.listRecent()
      .then { recents in
        vc.chats = recents
        self.router.setRoot(to: vc)
      }
      .catch { error in
        fatalError("failed to load recent chats with error: \(error.localizedDescription)")
      }

    vc.onAdd = { [unowned self] in
      self.runSearch()
    }

    vc.onChatSelect = { [unowned self] address in
      self.runChat(address: address)
    }

    userService = service
  }

  private func runSearch() {
    let coordinator = SearchCoordinator(socket: socket, router: router)
    coordinator.onFinish = { [unowned coordinator, unowned self] address in
      self.router.popModule()
      self.remove(childCoordinator: coordinator)
      self.runChat(address: address)
    }
    add(childCoordinator: coordinator)
    coordinator.start()
  }

  private func runChat(address: SignalAddress) {
    let coordinator = ChatCoordinator(account: account,
                                      dbQueue: dbQueue,
                                      socket: socket,
                                      router: router,
                                      address: address)
    add(childCoordinator: coordinator)
    coordinator.start()
  }
}

extension HomeCoordinator: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController,
                            didShow viewController: UIViewController,
                            animated: Bool) {
    guard
      let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
      !navigationController.viewControllers.contains(fromViewController) else { return }

    if fromViewController is SearchViewController {
      remove { $0 is SearchCoordinator }
    } else if fromViewController is ChatViewController {
      remove { $0 is ChatCoordinator }
    }
  }
}
