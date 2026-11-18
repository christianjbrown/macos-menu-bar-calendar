import AppKit

/// Starts AppKit as a menu bar app with no Dock icon.
@MainActor
public enum AppLauncher {
    public static func run(_ app: ApplicationRunning, delegate: NSApplicationDelegate) {
        app.delegate = delegate
        _ = app.setActivationPolicy(.accessory)
        app.run()
    }
}
