import XCTest
@testable import almost_secure
import SignalProtocol

class RemoteAccountServiceTests: XCTestCase {
  override func setUp() {
    super.setUp()

    App.reset()

    let _setUp = XCTestExpectation(description: "set up")

    Backend.cleanStorage()
      .then { _ in _setUp.fulfill() }
      .catch { error in fatalError("failed to clean storage with error: \(error)") }

    wait(for: [_setUp], timeout: 5.0)
  }

  func testRegistration() {
    let _register = XCTestExpectation(description: "register")

    AccountService
      .register(name: "alice")
      .then { account in
        XCTAssertEqual(account.address, SignalAddress(name: "alice", deviceId: 1))
        XCTAssertEqual(account.registrationID, 1)
      }
      .catch { error in
        XCTFail("AccountService.register failed with error: \(error.localizedDescription)")
      }
      .always { _register.fulfill() }

    wait(for: [_register], timeout: 5.0)
  }

  func testKeysUpload() {
    // create the account for which the keys are uploaded
    var _account: AppAccount!
    let _register = XCTestExpectation(description: "register")
    AccountService
      .register(name: "alice")
      .then { account in _account = account }
      .catch { error in XCTFail("AccountService.register failed with error: \(error)") }
      .always { _register.fulfill() }

    wait(for: [_register], timeout: 5.0)

    // identity pub key
    let _indentity = XCTestExpectation(description: "identity")
    AccountService
      .upload(identityKey: _account.identity.publicKey, for: _account.address)
      .catch { error in XCTFail("AccountService.upload failed with error: \(error)") }
      .always { _indentity.fulfill() }

    wait(for: [_indentity], timeout: 5.0)

    // pre keys
    let _preKeys = XCTestExpectation(description: "preKeys")
    let preKeys = try! Signal.generatePreKeys(start: 1, count: 100)
    AccountService.upload(preKeys: preKeys, for: _account.address)
      .catch { error in XCTFail("AccountService.upload failed with error: \(error)") }
      .always { _preKeys.fulfill() }

    wait(for: [_preKeys], timeout: 5.0)

    // signed pre key
    let _signedPreKey = XCTestExpectation(description: "signedPreKey")
    let signedPreKey = try! Signal.generate(signedPreKey: 1,
                                            identity: _account.identity,
                                            timestamp: UInt64(Date().timeIntervalSince1970))
    AccountService.upload(signedPreKey: signedPreKey, for: _account.address)
      .catch { error in XCTFail("AccountService.upload failed with error: \(error)") }
      .always { _signedPreKey.fulfill() }

    wait(for: [_signedPreKey], timeout: 5.0)

    // check that the uploaded keys were actually stored
    // by retrieving them
    // or find an easier way

    let _preKeyBundle = XCTestExpectation(description: "preKeyBundle")
    AccountService
      .preKeyBundle(for: SignalAddress(name: "alice", deviceId: 1))
      .then { preKeyBundle in
        XCTAssertEqual(preKeyBundle.identityKey, _account.identity.publicKey)

        XCTAssertEqual(preKeyBundle.registrationId, 1)

        XCTAssertEqual(preKeyBundle.signedPreKey.id, signedPreKey.id)
        XCTAssertEqual(preKeyBundle.signedPreKey.publicKey, signedPreKey.keyPair.publicKey)
        XCTAssertEqual(preKeyBundle.signedPreKey.signature, signedPreKey.signature)

        XCTAssertEqual(preKeyBundle.preKey.id, preKeys[0].id)
        XCTAssertEqual(preKeyBundle.preKey.publicKey, preKeys[0].keyPair.publicKey)
      }
      .catch { error in XCTFail("AccountService.preKeyBundle failed with error: \(error)") }
      .always { _preKeyBundle.fulfill() }

    wait(for: [_preKeyBundle], timeout: 10.0)
  }
}
