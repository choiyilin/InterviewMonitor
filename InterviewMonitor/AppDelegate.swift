import Cocoa
import FirebaseCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Configure Firebase SDK
    FirebaseApp.configure()
  }
}
