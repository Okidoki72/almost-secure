import GRDBCipher
import SignalProtocol
@testable import almost_secure

func setupStore(dbQueue: DatabaseQueue, makeKeys: Bool) throws -> SignalStore {
  let identity = try Signal.generateIdentityKeyPair()
  let registrationId = try Signal.generateRegistrationId()
  let store = try SignalStore(identityKeyStore: SQLCipherIdentityKeyStore(dbQueue: dbQueue,
                                                                          identity: identity,
                                                                          registrationId: registrationId),
                              preKeyStore: SQLCipherPreKeyStore(dbQueue: dbQueue),
                              sessionStore: SQLCipherSessionStore(dbQueue: dbQueue),
                              signedPreKeyStore: SQLCipherSignedPreKeyStore(dbQueue: dbQueue),
                              senderKeyStore: nil)

  if makeKeys {
    let preKeys = try Signal.generatePreKeys(start: 1, count: 100)
    try preKeys.forEach {
      _ = store.preKeyStore.store(preKey: try $0.data(), for: $0.id)
    }

    let signedPreKey = try Signal.generate(signedPreKey: 1, identity: identity, timestamp: 0)
    _ = store.signedPreKeyStore.store(signedPreKey: try signedPreKey.data(), for: signedPreKey.id)
  }

  return store
}
