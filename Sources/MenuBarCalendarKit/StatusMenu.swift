import AppKit
import CalendarCore

/// Shows a menu from the status item.
@MainActor
public protocol MenuPresenting: AnyObject {
    func present(_ menu: NSMenu, on item: NSStatusItem)
}

/// Builds the right-click menu.
@MainActor
enum StatusMenuFactory {
    static func make(strings: AppStrings, launchAtLoginEnabled: Bool, target: AnyObject,
                     toggleLaunchAtLogin: Selector) -> NSMenu {
        let menu = NSMenu()
        let login = NSMenuItem(title: strings.launchAtLogin, action: toggleLaunchAtLogin, keyEquivalent: "")
        login.target = target
        login.state = launchAtLoginEnabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: strings.quit,
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }
}

/// Opens a menu under the status item. The menu is attached only for this click,
/// so a later left click still opens the calendar.
@MainActor
public final class StatusItemMenuPresenter: MenuPresenting {
    public init() {}

    public func present(_ menu: NSMenu, on item: NSStatusItem) {
        item.menu = menu
        item.button!.performClick(nil)
        item.menu = nil
    }
}
