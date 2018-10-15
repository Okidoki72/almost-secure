import Foundation

enum HTTPError: Error {
  case urlSessionError(Error)
  case invalidResponse(URLResponse)
  case statusCodeError(Int)
  case noData
  case invalidPath
}

enum HTTP {
  private static let endpoint = URL(string: "http://192.168.1.44:4000/")!
  enum Method: String {
    case post = "POST"
  }
  
  static func request(_ method: Method, path: String, body: [String: Any]? = nil) throws -> URLRequest {
    guard let url = URL(string: path, relativeTo: endpoint) else {
      throw HTTPError.invalidPath
    }

    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue

    if let body = body {
      request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
      request.addValue("application/json", forHTTPHeaderField: "content-type")
    }

    return request
  }

  static func check(data: Data?,
                    response: URLResponse?,
                    error: Error?,
                    expectsData: Bool = false) -> HTTPError? {
    guard error == nil else { return .urlSessionError(error!) }
    guard let httpResponse = response as? HTTPURLResponse else { return .invalidResponse(response!) }
    guard 200..<300 ~= httpResponse.statusCode else { return .statusCodeError(httpResponse.statusCode) }
    if expectsData { guard data != nil else { return .noData } }
    return nil
  }
}
