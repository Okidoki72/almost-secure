import XCTest
@testable import almost_secure
import GRDBCipher
import SignalProtocol

/// signal store implementation sanity checks
class SignalStoresTests: XCTestCase {
  var dbQueue: DatabaseQueue!

  override func setUp() {
    dbQueue = try! AppDatabase.open(.temp, passphrase: "yay")
  }

  func testIdentityStore() {
    let identity = try! Signal.generateIdentityKeyPair()
    let registrationId = try! Signal.generateRegistrationId()

    let identityKeyStore: IdentityKeyStore = SQLCipherIdentityKeyStore(dbQueue: dbQueue,
                                                                       identity: identity,
                                                                       registrationId: registrationId)

    let fetchedIdentity = identityKeyStore.identityKeyPair()!
    XCTAssertEqual(fetchedIdentity.privateKey, identity.privateKey)
    XCTAssertEqual(fetchedIdentity.publicKey, identity.publicKey)
    XCTAssertEqual(identityKeyStore.localRegistrationId()!, registrationId)

    let bob = try! Signal.generateIdentityKeyPair()
    let bobAddress = SignalAddress(name: "bob", deviceId: 1)

    XCTAssert(identityKeyStore.isTrusted(identity: bob.publicKey, for: bobAddress)!)
    XCTAssert(identityKeyStore.save(identity: bob.publicKey, for: bobAddress))
    XCTAssert(!identityKeyStore.isTrusted(identity: identity.publicKey, for: bobAddress)!)
  }

  func testPreKeyStore() {
    let preKeyStore: PreKeyStore = SQLCipherPreKeyStore(dbQueue: dbQueue)

    let preKeys = try! Signal.generatePreKeys(start: 1, count: 2)

    XCTAssert(!preKeyStore.contains(preKey: preKeys[0].id))
    XCTAssertNil(preKeyStore.load(preKey: preKeys[0].id))

    XCTAssert(preKeyStore.store(preKey: try! preKeys[0].data(), for: preKeys[0].id))
    XCTAssertEqual(preKeyStore.load(preKey: preKeys[0].id)!, try! preKeys[0].data())

    XCTAssert(preKeyStore.store(preKey: try! preKeys[1].data(), for: preKeys[1].id))
    XCTAssertEqual(preKeyStore.load(preKey: preKeys[1].id)!, try! preKeys[1].data())

    XCTAssert(preKeyStore.remove(preKey: preKeys[0].id))

    XCTAssert(!preKeyStore.contains(preKey: preKeys[0].id))
    XCTAssertNil(preKeyStore.load(preKey: preKeys[0].id))

    XCTAssertEqual(preKeyStore.load(preKey: preKeys[1].id)!, try! preKeys[1].data())
  }

  func testSignedPreKeyStore() {
    let signedPreKeyStore: SignedPreKeyStore = SQLCipherSignedPreKeyStore(dbQueue: dbQueue)
    let identity = try! Signal.generateIdentityKeyPair()
    let signedPreKey = try! Signal.generate(signedPreKey: 1, identity: identity, timestamp: 0)

    XCTAssert(!signedPreKeyStore.contains(signedPreKey: signedPreKey.id))
    XCTAssertNil(signedPreKeyStore.load(signedPreKey: signedPreKey.id))

    XCTAssert(signedPreKeyStore.store(signedPreKey: try! signedPreKey.data(), for: signedPreKey.id))
    XCTAssertEqual(signedPreKeyStore.load(signedPreKey: signedPreKey.id)!, try! signedPreKey.data())

    XCTAssert(signedPreKeyStore.remove(signedPreKey: signedPreKey.id))

    XCTAssert(!signedPreKeyStore.contains(signedPreKey: signedPreKey.id))
    XCTAssertNil(signedPreKeyStore.load(signedPreKey: signedPreKey.id))
  }

  func testSessionStore() {
    let sessionStore: SessionStore = SQLCipherSessionStore(dbQueue: dbQueue)

    let bobAddress1 = SignalAddress(name: "bob", deviceId: 1)
    let bobAddress2 = SignalAddress(name: "bob", deviceId: 2)

    XCTAssert(!sessionStore.containsSession(for: bobAddress1))
    XCTAssertNil(sessionStore.loadSession(for: bobAddress1))

    let fakeSession1 = "asdfasdf".data(using: .ascii)!
    let fakeSession2 = "asdfadsfasdfasdf".data(using: .ascii)!
    let fakeUserRecord2 = "asdfasdasdfwqf".data(using: .ascii)!

    XCTAssert(sessionStore.store(session: fakeSession1, for: bobAddress1, userRecord: nil))
    XCTAssert(sessionStore.store(session: fakeSession2, for: bobAddress2, userRecord: fakeUserRecord2))

    XCTAssert(sessionStore.containsSession(for: bobAddress1))
    XCTAssertEqual(sessionStore.loadSession(for: bobAddress1)!.session, fakeSession1)
    XCTAssertNil(sessionStore.loadSession(for: bobAddress1)!.userRecord)

    XCTAssert(sessionStore.containsSession(for: bobAddress2))
    XCTAssertEqual(sessionStore.loadSession(for: bobAddress2)!.session, fakeSession2)
    XCTAssertEqual(sessionStore.loadSession(for: bobAddress2)!.userRecord!, fakeUserRecord2)

    XCTAssertEqual(sessionStore.subDeviceSessions(for: bobAddress1.name)!, [1, 2])

    XCTAssert(sessionStore.deleteSession(for: bobAddress1)!)

    XCTAssert(!sessionStore.containsSession(for: bobAddress1))
    XCTAssertNil(sessionStore.loadSession(for: bobAddress1))

    // TODO
    _ = sessionStore.deleteAllSessions(for: bobAddress1.name)

    XCTAssert(!sessionStore.containsSession(for: bobAddress2))
    XCTAssertNil(sessionStore.loadSession(for: bobAddress2))
  }
}
