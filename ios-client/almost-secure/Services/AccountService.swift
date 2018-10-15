import SignalProtocol
import Promises

enum AccountService {
  enum Status {
    case busy
    case idle
  }

  enum Error: Swift.Error {
    case deserializationError(Swift.Error)
    case signalError(SignalError)
    case httpError(HTTPError)
  }
}

extension AccountService {
  // can actually replace with channel join / socket connect
  static func register(name: String) -> Promise<AppAccount> {
    let promise = Promise<AppAccount>.pending()
    let req = try! HTTP.request(.post, path: "/register", body: ["name": name])
    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error, expectsData: true) {
        promise.reject(Error.httpError(httpError))
        return
      }

      let resp: [String: Any]
      do {
        resp = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
      } catch {
        promise.reject(Error.deserializationError(error))
        return
      }

      let deviceId: Int32 = 1 // TODO
      let registrationID = resp["id"] as! UInt32
      let account: AppAccount
      do {
        account = try AppAccount.create(address: SignalAddress(name: name, deviceId: deviceId),
                                        registrationID: registrationID)
      } catch let error as SignalError {
        promise.reject(Error.signalError(error))
        return
      } catch {
        fatalError("eh")
      }

      promise.fulfill(account)
    }

    task.resume()

    return promise
  }
}

//- MARK: Signal stuff
extension AccountService {
  static func upload(identityKey: Data, for address: SignalAddress) -> Promise<Void> {
    let promise = Promise<Void>.pending()
    let base64IdentityKey = identityKey.base64EncodedString()
    let req = try! HTTP.request(.post, path: "/upload", body: ["identity_key": base64IdentityKey, "name": address.name])
    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error) {
        promise.reject(Error.httpError(httpError))
        return
      }

      promise.fulfill(())
    }

    task.resume()
    return promise
  }

  static func upload(preKeys: [SessionPreKey], for address: SignalAddress) -> Promise<Void> {
    let promise = Promise<Void>.pending()

    let base64EncodedPreKeys = preKeys.map { preKey in
      return ["public_key": preKey.keyPair.publicKey.base64EncodedString(), "id": preKey.id]
    }

    let req = try! HTTP.request(.post, path: "/upload", body: ["pre_keys": base64EncodedPreKeys, "name": address.name])
    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error) {
        promise.reject(httpError)
        return
      }

      promise.fulfill(())
    }

    task.resume()
    return promise
  }

  static func upload(signedPreKey: SessionSignedPreKey, for address: SignalAddress) -> Promise<Void> {
    let promise = Promise<Void>.pending()

    let base64SignedPreKey: [String: Any] = ["id": signedPreKey.id,
                                             "public_key": signedPreKey.keyPair.publicKey.base64EncodedString(),
                                             "signature": signedPreKey.signature.base64EncodedString()]

    let req = try! HTTP.request(.post, path: "/upload", body: ["signed_pre_key": base64SignedPreKey, "name": address.name])
    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error) {
        promise.reject(httpError)
        return
      }

      promise.fulfill(())
    }

    task.resume()
    return promise
  }

  typealias _SignedPreKey = (id: UInt32, publicKey: Data, signature: Data)
  typealias _PreKey = (id: UInt32, publicKey: Data)
  typealias _PreKeyBundle = (registrationId: UInt32, identityKey: Data, signedPreKey: _SignedPreKey, preKey: _PreKey)

  static func preKeyBundle(for address: SignalAddress) -> Promise<_PreKeyBundle> {
    let promise = Promise<_PreKeyBundle>.pending()
    let req = try! HTTP.request(.post, path: "/pre_key_bundle", body: ["name": address.name])
    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error, expectsData: true) {
        promise.reject(httpError)
        return
      }

      let resp: [String: Any]
      do {
        resp = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
      } catch {
        promise.reject(error)
        return
      }

      let _preKey = resp["pre_key"] as! [String: Any]
      let _signedPreKey = resp["signed_pre_key"] as! [String: Any]

      let preKeyBundle = _PreKeyBundle(registrationId: resp["registration_id"] as! UInt32,
                                       identityKey: Data(base64Encoded: resp["identity_key"] as! String)!,
                                       signedPreKey: _SignedPreKey(id: _signedPreKey["id"] as! UInt32,
                                                                   publicKey: Data(base64Encoded: _signedPreKey["public_key"] as! String)!,
                                                                   signature: Data(base64Encoded: _signedPreKey["signature"] as! String)!),
                                       preKey: _PreKey(id: _preKey["id"] as! UInt32,
                                                       publicKey: Data(base64Encoded: _preKey["public_key"] as! String)!))

      promise.fulfill(preKeyBundle)
    }

    task.resume()
    return promise
  }
}
