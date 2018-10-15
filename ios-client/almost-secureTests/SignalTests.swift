import XCTest
@testable import almost_secure
import GRDBCipher
import SignalProtocol

class SignalTests: XCTestCase {
  var dbQueueAlice: DatabaseQueue!
  var dbQueueBob: DatabaseQueue!

  override func setUp() {
    dbQueueAlice = try! AppDatabase.open(.temp, passphrase: "yay")
    dbQueueBob = try! AppDatabase.open(.temp, passphrase: "hey")
  }

  func testEncryptionRoundtrip() {
    let aliceAddress = SignalAddress(name: "Alice", deviceId: 0)
    let aliceStore = try! setupStore(dbQueue: dbQueueAlice, makeKeys: true)
    let preKeyData = aliceStore.preKeyStore.load(preKey: 1)!
    let preKey = try! SessionPreKey(from: preKeyData)
    let signedPreKey = try! SessionSignedPreKey(from: aliceStore.signedPreKeyStore.load(signedPreKey: 1)!)
    let bundle = SessionPreKeyBundle(registrationId: aliceStore.identityKeyStore.localRegistrationId()!,
                                     deviceId: aliceAddress.deviceId,
                                     preKeyId: preKey.id,
                                     preKey: preKey.keyPair.publicKey,
                                     signedPreKeyId: signedPreKey.id,
                                     signedPreKey: signedPreKey.keyPair.publicKey,
                                     signature: signedPreKey.signature,
                                     identityKey: aliceStore.identityKeyStore.identityKeyPair()!.publicKey)

    let bobAddress = SignalAddress(name: "Bob", deviceId: 0)
    let bobStore = try! setupStore(dbQueue: dbQueueBob, makeKeys: false)
    try! SessionBuilder(for: aliceAddress, in: bobStore).process(preKeyBundle: bundle)
    let message = "From Bob to Alice with love".data(using: .utf8)!
    let bobSessionCipher = SessionCipher(for: aliceAddress, in: bobStore)
    let encryptedMessage = try! bobSessionCipher.encrypt(message)

    let aliceSessionCipher = SessionCipher(for: bobAddress, in: aliceStore)
    let decryptedMessage = try! aliceSessionCipher.decrypt(message: encryptedMessage)

    XCTAssertEqual(message, decryptedMessage)
  }
}
