import AppKit

/// Builds the app controller once AppKit has finished launching.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let makeController: @MainActor () -> AppController
    private(set) var controller: AppController?

    public init(makeController: @escaping @MainActor () -> AppController) {
        self.makeController = makeController
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = makeController()
        controller.start()
        self.controller = controller
    }
}
