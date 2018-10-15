@testable import almost_secure
import Foundation
import Promises

enum Backend {
  static func cleanStorage() -> Promise<Void> {
    let promise = Promise<Void>.pending()
    let request = try! HTTP.request(.post, path: "/clean_storage")
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error, expectsData: true) {
        promise.reject(httpError)
        return
      }

      promise.fulfill(())
    }

    task.resume()
    return promise
  }

  static func createAddress(name: String) -> Promise<Void> {
    let promise = Promise<Void>.pending()
    let request = try! HTTP.request(.post, path: "/register", body: ["name": name])
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let httpError = HTTP.check(data: data, response: response, error: error, expectsData: true) {
        promise.reject(httpError)
        return
      }

      promise.fulfill(())
    }

    task.resume()
    return promise
  }
}
