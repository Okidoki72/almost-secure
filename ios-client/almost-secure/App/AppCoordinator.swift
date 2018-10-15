import GRDBCipher
import SignalProtocol

private func mainDatabaseURL() throws -> URL {
  return try FileManager.default
    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    .appendingPathComponent("db.sqlite")
}

private func openDatabase(passphrase: String) throws -> DatabaseQueue {
  let databaseURL = try mainDatabaseURL()
  let dbQueue = try AppDatabase.open(.onDisk(path: databaseURL.path), passphrase: passphrase)
  dbQueue.setupMemoryManagement(in: .shared)
  return dbQueue
}

final class AppCoordinator: BaseCoordinator {
  private let router: Router

  init(router: Router) {
    self.router = router
  }

  override func start() {
    start(uploadKeys: false)
  }

  // TODO dirty hack :(
  // TODO async upload keys after registration:
  // - separate signal store from account
  private func start(uploadKeys: Bool) {
    if uploadKeys {
      let account = AppAccount.load()!
      let dbQueue = try! openDatabase(passphrase: account.dbPassphrase)
      asyncKeyUpload(account: account, dbQueue: dbQueue)
      runHome(account: account, dbQueue: dbQueue)
    } else {
      if let account = AppAccount.load() {
        let dbQueue = try! openDatabase(passphrase: account.dbPassphrase)
        runHome(account: account, dbQueue: dbQueue)
      } else {
        runRegistration()
      }
    }
  }

  private func runRegistration() {
    let coordinator = RegistrationCoordinator(router: router)
    coordinator.onSuccess = { [unowned self, unowned coordinator] in
      self.remove(childCoordinator: coordinator)
      self.start(uploadKeys: true)
    }
    add(childCoordinator: coordinator)
    coordinator.start()
  }

  private func runHome(account: AppAccount, dbQueue: DatabaseQueue) {
    let coordinator = HomeCoordinator(account: account, dbQueue: dbQueue, router: router)
    add(childCoordinator: coordinator)
    coordinator.start()
  }

  // TODO track errors / retry
  private func asyncKeyUpload(account: AppAccount, dbQueue: DatabaseQueue) {
    DispatchQueue.global(qos: .background).async {
      let store = try! account.store(dbQueue: dbQueue)
      let signalService = SignalService(store: store)
      let preKeys = try! signalService.generatePreKeys(start: 1, count: 100)
      let signedPreKey = try! signalService.generateSignedPreKey(id: 1, identity: account.identity)

      AccountService
        .upload(identityKey: account.identity.publicKey, for: account.address)
        .catch { error in fatalError("failed to upload identity key with error: \(error)") }

      AccountService
        .upload(preKeys: preKeys, for: account.address)
        .catch { error in fatalError("failed to upload pre keys with error: \(error)") }

      AccountService
        .upload(signedPreKey: signedPreKey, for: account.address)
        .catch { error in fatalError("failed to upload signed pre key with error: \(error)") }
    }
  }
}
