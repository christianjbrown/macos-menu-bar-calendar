import AppKit
import CalendarCore
@testable import MenuBarCalendarKit

@MainActor
func appTests() {
    let t = TestRun.shared
    let calendar = gregorian()

    // MARK: CalendarViewController

    func makeController(_ now: Date = date(2026, 11, 18), strings: AppStrings = .english)
        -> (CalendarViewController, FakeClock) {
        let clock = FakeClock(now)
        return (CalendarViewController(clock: clock, calendar: calendar, strings: strings), clock)
    }
    func titles(_ controller: CalendarViewController) -> [String] {
        controller.titleButtons.filter { !$0.isHidden }.map(\.title)
    }

    t.run("CalendarViewController", "is never built from a nib") {
        try expect(CalendarViewController(coder: NSCoder()) == nil)
    }
    t.run("CalendarViewController", "opens on today's month with localised tooltips") {
        let (controller, _) = makeController(strings: .german)
        _ = controller.view
        try expectEqual(titles(controller), ["November", "2026"])
        try expectEqual(controller.previousButton.toolTip, "Zurück")
        try expectEqual(controller.nextButton.toolTip, "Weiter")
        try expect(controller.grid.delegate === controller)
        guard case .days(let grid, let today, _)? = controller.grid.page else { throw TestFailure(description: "not days") }
        try expectEqual(grid.month, Month(year: 2026, month: 11))
        try expectEqual(today, Day(year: 2026, month: 11, day: 18))
    }
    t.run("CalendarViewController", "zooms out from the title and back down from the grid") {
        let (controller, _) = makeController()
        _ = controller.view
        controller.titleButtons[0].performClick(nil)
        try expectEqual(controller.state.mode, .months)
        try expectEqual(titles(controller), ["2026"])
        controller.titleButtons[0].performClick(nil)
        try expectEqual(controller.state.mode, .years)
        try expectEqual(titles(controller), ["2021 - 2032"])
        controller.titleButtons[0].performClick(nil)
        try expectEqual(controller.state.mode, .years, "the range is not a link")
        controller.gridView(controller.grid, didRequest: .pickYear(2028))
        controller.gridView(controller.grid, didRequest: .pickMonth(Month(year: 2028, month: 5)))
        try expectEqual(titles(controller), ["May", "2028"])
        controller.titleButtons[1].performClick(nil)
        try expectEqual(controller.state.mode, .years)
    }
    t.run("CalendarViewController", "pages with the arrow buttons") {
        let (controller, _) = makeController()
        _ = controller.view
        controller.nextButton.performClick(nil)
        try expectEqual(controller.state.month, Month(year: 2026, month: 12))
        controller.previousButton.performClick(nil)
        controller.previousButton.performClick(nil)
        try expectEqual(controller.state.month, Month(year: 2026, month: 10))
        controller.titleButtons[1].performClick(nil)
        controller.nextButton.performClick(nil)
        try expectEqual(controller.state.years, 2027..<2039)
    }
    t.run("CalendarViewController", "handles keys, scrolling and dismissal") {
        let (controller, _) = makeController()
        let dismisser = FakeDismisser()
        controller.dismisser = dismisser
        _ = controller.view
        try expect(controller.gridView(controller.grid, handle: .right))
        try expectEqual(controller.state.selected, Day(year: 2026, month: 11, day: 19))
        try expect(controller.gridView(controller.grid, handle: .other("\u{1b}")))
        try expectEqual(dismisser.closeCount, 1)
        try expect(!controller.gridView(controller.grid, handle: .other("x")))
        controller.gridView(controller.grid, didScroll: 2)
        try expectEqual(controller.state.month, Month(year: 2027, month: 1))
    }
    t.run("CalendarViewController", "always reopens on this month with today selected") {
        let (controller, clock) = makeController()
        _ = controller.view
        controller.titleButtons[1].performClick(nil)
        controller.nextButton.performClick(nil)
        clock.current = date(2026, 12, 2)
        controller.showToday()
        try expectEqual(controller.state, CalendarState(today: Day(year: 2026, month: 12, day: 2)))
        try expectEqual(titles(controller), ["December", "2026"])
    }
    t.run("CalendarViewController", "follows the date when it changes") {
        let (controller, clock) = makeController(date(2026, 11, 30))
        _ = controller.view
        clock.current = date(2026, 12, 1)
        controller.refreshToday()
        try expectEqual(controller.state.today, Day(year: 2026, month: 12, day: 1))
        try expectEqual(titles(controller), ["December", "2026"])
    }
    t.run("CalendarViewController", "puts keyboard focus on the grid") {
        let (controller, _) = makeController()
        let window = hostWindow(for: controller.view, size: NSSize(width: 230, height: 220))
        controller.focusGrid()
        try expect(window.firstResponder === controller.grid)
    }

    // MARK: CalendarPopover

    t.run("CalendarPopover", "shows today's month under a view and closes") {
        let (controller, clock) = makeController()
        let popover = CalendarPopover(content: controller)
        try expect(controller.dismisser === popover)
        try expectEqual(popover.popover.behavior, .transient)
        try expect(!popover.popover.animates)

        let anchor = NSView(frame: NSRect(x: 0, y: 0, width: 40, height: 20))
        let window = hostWindow(for: anchor, size: anchor.frame.size)
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        controller.titleButtons.first?.performClick(nil)
        clock.current = date(2027, 1, 5)
        popover.show(from: anchor)
        try expect(popover.isShown)
        try expectEqual(controller.state, CalendarState(today: Day(year: 2027, month: 1, day: 5)))
        popover.close()
        spinRunLoop()
        try expect(!popover.isShown)
    }

    // MARK: Menu, errors, day changes, login default

    t.run("StatusMenuFactory", "builds a localised menu with the login item ticked") {
        let target = NSObject()
        let on = StatusMenuFactory.make(strings: .danish, launchAtLoginEnabled: true, target: target,
                                        toggleLaunchAtLogin: #selector(NSObject.description))
        try expectEqual(on.items.map(\.title), ["Åbn ved login", "", "Slut MenuBarCalendar"])
        try expectEqual(on.items[0].state, .on)
        try expect(on.items[0].target === target)
        try expectEqual(on.items[2].action, #selector(NSApplication.terminate(_:)))
        let off = StatusMenuFactory.make(strings: .english, launchAtLoginEnabled: false, target: target,
                                         toggleLaunchAtLogin: #selector(NSObject.description))
        try expectEqual(off.items[0].state, .off)
    }
    t.run("StatusItemMenuPresenter", "attaches the menu only while it is open") {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        nonisolated(unsafe) let menu = NSMenu()
        menu.addItem(withTitle: "Test", action: nil, keyEquivalent: "")
        let closer = Timer(timeInterval: 0.2, repeats: false) { _ in MainActor.assumeIsolated { menu.cancelTracking() } }
        RunLoop.main.add(closer, forMode: .common)
        StatusItemMenuPresenter().present(menu, on: item)
        closer.invalidate()
        try expect(item.menu == nil)
    }
    t.run("AlertErrorPresenter", "shows the error under a fixed headline") {
        let presenter = AlertErrorPresenter(title: "Headline")
        let alert = presenter.makeAlert(for: NSError(domain: "test", code: 1,
                                                     userInfo: [NSLocalizedDescriptionKey: "Details"]))
        try expectEqual(alert.messageText, "Headline")
        try expectEqual(alert.informativeText, "")
        let closer = Timer(timeInterval: 0.2, repeats: false) { _ in MainActor.assumeIsolated { NSApp.abortModal() } }
        RunLoop.main.add(closer, forMode: .common)
        presenter.present(FakeError())
        closer.invalidate()
    }
    t.run("DayChangeObserver", "reports midnight, clock, time zone and wake notifications") {
        let center = NotificationCenter()
        let workspace = NotificationCenter()
        let observer = DayChangeObserver(center: center, workspaceCenter: workspace)
        var count = 0
        observer.start { count += 1 }
        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemClockDidChange, .NSSystemTimeZoneDidChange] {
            center.post(name: name, object: nil)
        }
        workspace.post(name: NSWorkspace.didWakeNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        spinRunLoop()
        try expectEqual(count, 4)
    }
    t.run("LaunchAtLoginDefault", "turns Launch at Login on once") {
        let loginItem = FakeLoginItem()
        let settings = FakeSettings()
        let defaulter = LaunchAtLoginDefault(loginItem: loginItem, settings: settings)
        defaulter.apply()
        try expectEqual(loginItem.registerCount, 1)
        try expectEqual(settings.values[LaunchAtLoginDefault.appliedKey], true)
        try loginItem.unregister()
        defaulter.apply()
        try expectEqual(loginItem.registerCount, 1, "switching it off sticks")
    }
    t.run("LaunchAtLoginDefault", "tries again next launch if registering fails") {
        let loginItem = FakeLoginItem()
        loginItem.error = FakeError()
        let settings = FakeSettings()
        LaunchAtLoginDefault(loginItem: loginItem, settings: settings).apply()
        try expectEqual(settings.values[LaunchAtLoginDefault.appliedKey], nil)
        loginItem.error = nil
        LaunchAtLoginDefault(loginItem: loginItem, settings: settings).apply()
        try expectEqual(loginItem.registerCount, 2)
        try expectEqual(settings.values[LaunchAtLoginDefault.appliedKey], true)
    }
    t.run("SystemClock", "reads the current time") {
        let before = Date()
        let now = SystemClock().now()
        try expect(now >= before && now <= Date())
    }

    // MARK: AppController

    @MainActor
    final class Harness {
        let presenter = FakePresenter()
        let today = FakeToday()
        let dayChanges = FakeDayChanges()
        let loginItem = FakeLoginItem()
        let settings = FakeSettings()
        let menuPresenter = FakeMenuPresenter()
        let errorPresenter = FakeErrorPresenter()
        let events = FakeEvents()
        let activator = FakeActivator()
        let controller: AppController

        init() {
            controller = AppController(dependencies: .init(
                strings: .french, statusBar: NSStatusBar.system, presenter: presenter, today: today,
                dayChanges: dayChanges, loginItem: loginItem,
                launchAtLoginDefault: LaunchAtLoginDefault(loginItem: loginItem, settings: settings),
                menuPresenter: menuPresenter, errorPresenter: errorPresenter, events: events, activator: activator))
        }

        func tearDown() {
            if let item = controller.statusItem { NSStatusBar.system.removeStatusItem(item) }
        }
    }

    t.run("AppController", "puts a localised icon in the menu bar and applies the login default") {
        let h = Harness()
        defer { h.tearDown() }
        h.controller.start()
        let item = h.controller.statusItem!
        try expectEqual(item.autosaveName, AppController.autosaveName)
        try expect(item.button!.image!.isTemplate)
        try expectEqual(item.button!.toolTip, "Calendrier")
        try expect(item.button!.target === h.controller)
        try expectEqual(h.loginItem.registerCount, 1)
        h.dayChanges.onChange!()
        try expectEqual(h.today.refreshCount, 1)
    }
    t.run("AppController", "toggles the calendar on a plain click") {
        let h = Harness()
        defer { h.tearDown() }
        h.controller.start()
        let button = h.controller.statusItem!.button!
        h.events.currentEvent = mouseEvent(.leftMouseUp)
        h.controller.statusItemClicked(button)
        try expect(h.presenter.shownFrom === button)
        try expectEqual(h.activator.activations, [true])
        h.controller.statusItemClicked(button)
        try expectEqual(h.presenter.closeCount, 1)
        try expect(!h.presenter.isShown)
    }
    t.run("AppController", "opens the menu on a right click") {
        let h = Harness()
        defer { h.tearDown() }
        h.controller.start()
        h.presenter.isShown = true
        h.events.currentEvent = mouseEvent(.rightMouseUp)
        h.controller.statusItemClicked(h.controller.statusItem!.button!)
        try expectEqual(h.presenter.closeCount, 1)
        try expect(h.menuPresenter.item === h.controller.statusItem)
        try expectEqual(h.menuPresenter.menu!.items.first!.title, "Ouvrir à la connexion")
        try expectEqual(h.menuPresenter.menu!.items.first!.state, .on)
    }
    t.run("AppController", "switches Launch at Login and reports failures") {
        let h = Harness()
        h.controller.toggleLaunchAtLogin()
        try expectEqual(h.loginItem.registerCount, 1)
        h.controller.toggleLaunchAtLogin()
        try expectEqual(h.loginItem.unregisterCount, 1)
        h.loginItem.error = FakeError()
        h.controller.toggleLaunchAtLogin()
        try expectEqual(h.errorPresenter.errors.count, 1)
    }

    // MARK: AppDelegate, AppLauncher, AppComposition

    t.run("AppDelegate", "builds and starts the controller after launch") {
        let h = Harness()
        defer { h.tearDown() }
        let delegate = AppDelegate { h.controller }
        try expect(delegate.controller == nil)
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        try expect(delegate.controller === h.controller)
        try expect(h.controller.statusItem != nil)
    }
    t.run("AppLauncher", "runs as an accessory app with the delegate") {
        let app = FakeApplication()
        let delegate = AppDelegate { Harness().controller }
        AppLauncher.run(app, delegate: delegate)
        try expect(app.delegate === delegate)
        try expectEqual(app.policy, .accessory)
        try expect(app.didRun)
    }
    t.run("AppComposition", "wires the real services together") {
        let controller = AppComposition.makeController()
        try expect(controller.statusItem == nil, "nothing appears until start")
    }
}
