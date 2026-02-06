#if os(macOS)
import SwiftUI
import CodexBarCore
import Logging

@main
struct CodexBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            PreferencesView(
                settingsStore: appDelegate.settingsStore,
                usageStore: appDelegate.usageStore
            )
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    let usageStore: UsageStore
    private var statusItemController: StatusItemController?
    private let logger = Logger(label: "com.steipete.CodexBar")

    override init() {
        self.usageStore = UsageStore(settingsStore: settingsStore)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("CodexBar starting up")

        // Hide the dock icon - menu bar only
        NSApp.setActivationPolicy(.accessory)

        // Set up the status item controller
        statusItemController = StatusItemController(
            settingsStore: settingsStore,
            usageStore: usageStore
        )

        // Begin initial refresh
        Task {
            await usageStore.refresh()
        }

        logger.info("CodexBar ready")
    }

    func applicationWillTerminate(_ notification: Notification) {
        logger.info("CodexBar shutting down")
    }
}

#else
// Non-macOS platforms: provide a placeholder main
@main
struct CodexBarApp {
    static func main() {
        print("CodexBar is a macOS menu bar application.")
        print("Run on macOS 14+ to use the full GUI.")
    }
}
#endif
