import SignalProtocol

final class SignalService {
  private let store: SignalStore

  init(store: SignalStore) {
    self.store = store
  }

  func generatePreKeys(start: UInt32, count: Int) throws -> [SessionPreKey] {
    let preKeys = try Signal.generatePreKeys(start: start, count: count)
    try preKeys.forEach {
      _ = store.preKeyStore.store(preKey: try $0.data(), for: $0.id)
    }
    return preKeys
  }

  func generateSignedPreKey(id: UInt32, identity: KeyPair) throws -> SessionSignedPreKey {
    let signedPreKey = try Signal.generate(signedPreKey: id,
                                           identity: identity,
                                           timestamp: UInt64(Date().timeIntervalSince1970))
    _ = store.signedPreKeyStore.store(signedPreKey: try signedPreKey.data(), for: signedPreKey.id)
    return signedPreKey
  }
}
