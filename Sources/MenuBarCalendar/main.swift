import AppKit
import MenuBarCalendarKit

MainActor.assumeIsolated {
    let delegate = AppDelegate(makeController: AppComposition.makeController)
    AppLauncher.run(NSApplication.shared, delegate: delegate)
}
