import KeychainSwift
import SignalProtocol
import GRDBCipher

// TODO AppAccount<Registered | Unregistered> ???
// enum AppAccount
final class AppAccount {
  // TODO is it safe enough to synchronize private keys and passphrases over iCloud?
  private static let keychain = KeychainSwift()
  private static var _store: SignalStore?

  let registrationID: UInt32
  let identity: KeyPair
  let dbPassphrase: String
  let address: SignalAddress

  func store(dbQueue: DatabaseQueue) throws -> SignalStore {
    if let store = AppAccount._store {
      return store
    } else {
      let store = try AppAccount.openStore(identity: identity,
                                           registrationID: registrationID,
                                           dbQueue: dbQueue)
      AppAccount._store = store
      return store
    }
  }

  private static func openStore(identity: KeyPair,
                                registrationID: UInt32,
                                dbQueue: DatabaseQueue) throws -> SignalStore {
    return try SignalStore(identityKeyStore: SQLCipherIdentityKeyStore(dbQueue: dbQueue,
                                                                       identity: identity,
                                                                       registrationId: registrationID),
                           preKeyStore: SQLCipherPreKeyStore(dbQueue: dbQueue),
                           sessionStore: SQLCipherSessionStore(dbQueue: dbQueue),
                           signedPreKeyStore: SQLCipherSignedPreKeyStore(dbQueue: dbQueue),
                           senderKeyStore: nil)
  }

  private enum KeychainKeys {
    static let identityPrivateKey = "identityPrivateKey"
    static let dbPassphrase = "dbPassphrase"
  }

  private enum UserDefaultsKeys {
    static let registrationID = "registrationID"
    static let identityPublicKey = "identityPublicKey"
    static let addressName = "addressName"
    static let addressDeviceId = "addressDeviceId"
  }

  init(address: SignalAddress,
       registrationID: UInt32,
       identity: KeyPair,
       dbPassphrase: String) {
    self.address = address
    self.registrationID = registrationID
    self.identity = identity
    self.dbPassphrase = dbPassphrase
  }

  static func create(address: SignalAddress, registrationID: UInt32) throws -> AppAccount {
    func persist(address: SignalAddress) {
      UserDefaults.standard.set(address.name, forKey: UserDefaultsKeys.addressName)
      UserDefaults.standard.set(address.deviceId, forKey: UserDefaultsKeys.addressDeviceId)
    }

    func persist(registrationID: UInt32) {
      UserDefaults.standard.set(Int(registrationID), forKey: UserDefaultsKeys.registrationID)
    }

    persist(address: address)
    persist(registrationID: registrationID)

    func identity() throws -> KeyPair {
      let identityKeyPair = try! Signal.generateIdentityKeyPair()
      AppAccount.keychain.set(identityKeyPair.privateKey, forKey: KeychainKeys.identityPrivateKey)
      UserDefaults.standard.set(identityKeyPair.publicKey, forKey: UserDefaultsKeys.identityPublicKey)
      return identityKeyPair
    }

    func dbPassphrase() -> String {
      // TODO create a strongly random passphrase
      let passphrase = UUID().uuidString
      AppAccount.keychain.set(passphrase, forKey: KeychainKeys.dbPassphrase)
      return passphrase
    }

    return AppAccount(address: address,
                      registrationID: registrationID,
                      identity: try identity(),
                      dbPassphrase: dbPassphrase())
  }

  static func load() -> AppAccount? {
    guard
      let addressName = UserDefaults.standard.string(forKey: UserDefaultsKeys.addressName),
      let addressDeviceId = UserDefaults.standard.object(forKey: UserDefaultsKeys.addressDeviceId) as? Int,
      let registrationID = UserDefaults.standard.object(forKey: UserDefaultsKeys.registrationID) as? Int, // TODO
      let identityPrivateKey = AppAccount.keychain.getData(KeychainKeys.identityPrivateKey),
      let identityPublicKey = UserDefaults.standard.data(forKey: UserDefaultsKeys.identityPublicKey),
      let passphrase = AppAccount.keychain.get(KeychainKeys.dbPassphrase) else { return nil }

    return AppAccount(address: SignalAddress(name: addressName, deviceId: Int32(addressDeviceId)),
                      registrationID: UInt32(registrationID),
                      identity: KeyPair(publicKey: identityPublicKey, privateKey: identityPrivateKey),
                      dbPassphrase: passphrase)
  }
}

#if DEBUG
extension AppAccount {
  static func clear() {
    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    UserDefaults.standard.synchronize()
    AppAccount.keychain.clear()
  }
}
#endif
