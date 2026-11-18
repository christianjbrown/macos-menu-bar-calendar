import AppKit

/// Shows and hides the calendar next to the status item.
@MainActor
public protocol CalendarPresenting: AnyObject {
    var isShown: Bool { get }
    func show(from view: NSView)
    func close()
}

/// Presents the calendar in a transient popover that closes when you click elsewhere.
@MainActor
public final class CalendarPopover: CalendarPresenting, CalendarDismissing {
    let popover = NSPopover()
    private let content: CalendarViewController

    public init(content: CalendarViewController) {
        self.content = content
        popover.contentViewController = content
        popover.behavior = .transient
        popover.animates = false
        content.dismisser = self
    }

    public var isShown: Bool {
        popover.isShown
    }

    public func show(from view: NSView) {
        content.showToday()
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        content.view.window?.makeKey()
        content.focusGrid()
    }

    public func close() {
        popover.performClose(nil)
    }
}
