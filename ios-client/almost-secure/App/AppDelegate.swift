import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  private lazy var appCoordinator: AppCoordinator = {
    AppCoordinator(router: Router(rootController: rootController))
  }()

  private lazy var rootController: UINavigationController = {
    UINavigationController()
  }()

  var window: UIWindow?

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = rootController
    window?.makeKeyAndVisible()
    appCoordinator.start()
    return true
  }
}
