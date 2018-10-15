import Birdsong
import SignalProtocol

final class SearchCoordinator: BaseCoordinator {
  private let router: Router
  private let socket: Socket

  var onFinish: ((SignalAddress) -> Void)?

  init(socket: Socket, router: Router) {
    self.router = router
    self.socket = socket
  }

  override func start() {
    let searchChannel = SearchChannel(channel: socket.channel(AppChannels.search))
    let service = SearchService(channel: searchChannel)
    showSearch(service: service)
  }

  private func showSearch(service: SearchService) {
    let vc = SearchViewController.instantiate()

    vc.onInput = { [unowned vc] input in // TODO debounce
      service.search(for: input)
        .then { addresses in vc.foundAddresses = addresses }
        .catch { error in fatalError("failed with error: \(error)") }
    }

    vc.onAddressSelect = { [weak self] address in
      self?.onFinish?(address)
    }

    router.push(vc)
  }
}
