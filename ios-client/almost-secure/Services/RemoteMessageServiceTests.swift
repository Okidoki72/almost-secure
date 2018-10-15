import XCTest
@testable import almost_secure
import SignalProtocol
import Birdsong
import GRDBCipher

class RemoteMessageServiceTests: XCTestCase {
  var dbQueueAlice: DatabaseQueue!
  var dbQueueBob: DatabaseQueue!

  override func setUp() {
    dbQueueAlice = try! AppDatabase.open(.temp, passphrase: "yay")
    dbQueueBob = try! AppDatabase.open(.temp, passphrase: "hey")
  }

  func testSendReceive() {
    // setup signal stores
    let aliceAddress = SignalAddress(name: "alice", deviceId: 0)
    let aliceStore = try! setupStore(dbQueue: dbQueueAlice, makeKeys: true)
    let preKeyData = aliceStore.preKeyStore.load(preKey: 1)!
    let preKey = try! SessionPreKey(from: preKeyData)
    let signedPreKey = try! SessionSignedPreKey(from: aliceStore.signedPreKeyStore.load(signedPreKey: 1)!)
    let aliceBundle = SessionPreKeyBundle(registrationId: aliceStore.identityKeyStore.localRegistrationId()!,
                                          deviceId: aliceAddress.deviceId,
                                          preKeyId: preKey.id,
                                          preKey: preKey.keyPair.publicKey,
                                          signedPreKeyId: signedPreKey.id,
                                          signedPreKey: signedPreKey.keyPair.publicKey,
                                          signature: signedPreKey.signature,
                                          identityKey: aliceStore.identityKeyStore.identityKeyPair()!.publicKey)

    let bobAddress = SignalAddress(name: "bob", deviceId: 0)
    let bobStore = try! setupStore(dbQueue: dbQueueBob, makeKeys: true)
    try! SessionBuilder(for: aliceAddress, in: bobStore).process(preKeyBundle: aliceBundle)
    let bobSessionCipher = SessionCipher(for: aliceAddress, in: bobStore)
    let aliceSessionCipher = SessionCipher(for: bobAddress, in: aliceStore)

    // connect
    let aliceSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": aliceAddress.name])
    let bobSocket = Socket(url: "http://localhost:4000/socket/websocket", params: ["name": bobAddress.name])

    let aliceConnectExpectation = XCTestExpectation(description: "aliceSocketConnect")
    aliceSocket.onConnect = { aliceConnectExpectation.fulfill() }
    aliceSocket.connect()

    let bobConnectExpectation = XCTestExpectation(description: "bobSocketConnect")
    bobSocket.onConnect = { bobConnectExpectation.fulfill() }
    bobSocket.connect()

    wait(for: [aliceConnectExpectation, bobConnectExpectation], timeout: 10.0)

    // actually test
    let aliceExpectsHello = XCTestExpectation(description: "aliceExpectsHello")
    let bobExpectsHello = XCTestExpectation(description: "bobExpectsHello")

    let aliceListens = { (message: String) in
      XCTAssertEqual(message, "hello alice")
      aliceExpectsHello.fulfill()
    }

    let bobListens = { (message: String) in
      XCTAssertEqual(message, "hello bob")
      bobExpectsHello.fulfill()
    }

    let channelName = AppChannels.chat(names: [aliceAddress.name, bobAddress.name])

    let bobMessageService = MessageService(channel: ChatChannel(channel: bobSocket.channel(channelName)),
                                           cipher: bobSessionCipher,
                                           onNewMessage: bobListens)

    _ = bobMessageService.start()

    let aliceMessageService = MessageService(channel: ChatChannel(channel: aliceSocket.channel(channelName)),
                                             cipher: aliceSessionCipher,
                                             onNewMessage: aliceListens)

    _ = aliceMessageService.start()

    bobMessageService.send("hello alice").catch { error in
      XCTFail("failed to send a message with error: \(error)")
    }

    wait(for: [aliceExpectsHello], timeout: 10.0)

    aliceMessageService.send("hello bob").catch { error in
      XCTFail("failed to send a message with error: \(error)")
    }

    wait(for: [bobExpectsHello], timeout: 10.0)
  }
}
