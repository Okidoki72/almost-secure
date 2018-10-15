#if DEBUG
enum App {
  static func reset() {
    try? AppDatabase.drop()
    AppAccount.clear()
  }
}
#endif
