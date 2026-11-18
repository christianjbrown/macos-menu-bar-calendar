import AppKit

/// Reports when "today" may have changed.
@MainActor
public protocol DayChangeSource: AnyObject {
    func start(onChange: @escaping @MainActor () -> Void)
}

/// Watches for midnight, clock and time zone changes, and waking from sleep.
@MainActor
public final class DayChangeObserver: DayChangeSource {
    private let center: NotificationCenter
    private let workspaceCenter: NotificationCenter
    private var tokens: [NSObjectProtocol] = []

    public init(center: NotificationCenter, workspaceCenter: NotificationCenter) {
        self.center = center
        self.workspaceCenter = workspaceCenter
    }

    public func start(onChange: @escaping @MainActor () -> Void) {
        let sources: [(NotificationCenter, Notification.Name)] = [
            (center, .NSCalendarDayChanged),
            (center, .NSSystemClockDidChange),
            (center, .NSSystemTimeZoneDidChange),
            (workspaceCenter, NSWorkspace.didWakeNotification),
        ]
        tokens = sources.map { center, name in
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { onChange() }
            }
        }
    }
}
