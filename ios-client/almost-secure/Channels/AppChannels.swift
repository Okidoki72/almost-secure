enum AppChannels {
  static func user(name: String) -> String {
    return "user:\(name)"
  }

  static let search = "search"

  static func chat(names: [String]) -> String {
    let sortedNames = names.sorted()
    return "chats:\(sortedNames[0]):\(sortedNames[1])"
  }
}
