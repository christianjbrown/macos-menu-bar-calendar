import AppKit
import CalendarCore

/// Owns the status item and decides what a click on it does.
@MainActor
public final class AppController: NSObject {
    public struct Dependencies {
        let strings: AppStrings
        let statusBar: StatusBarProviding
        let presenter: CalendarPresenting
        let today: TodayRefreshing
        let dayChanges: DayChangeSource
        let loginItem: LoginItemService
        let launchAtLoginDefault: LaunchAtLoginDefault
        let menuPresenter: MenuPresenting
        let errorPresenter: ErrorPresenting
        let events: EventSource
        let activator: AppActivating

        public init(strings: AppStrings, statusBar: StatusBarProviding, presenter: CalendarPresenting, today: TodayRefreshing,
                    dayChanges: DayChangeSource, loginItem: LoginItemService,
                    launchAtLoginDefault: LaunchAtLoginDefault, menuPresenter: MenuPresenting,
                    errorPresenter: ErrorPresenting, events: EventSource, activator: AppActivating) {
            self.strings = strings
            self.statusBar = statusBar
            self.presenter = presenter
            self.today = today
            self.dayChanges = dayChanges
            self.loginItem = loginItem
            self.launchAtLoginDefault = launchAtLoginDefault
            self.menuPresenter = menuPresenter
            self.errorPresenter = errorPresenter
            self.events = events
            self.activator = activator
        }
    }

    static let autosaveName = "MenuBarCalendarStatusItem"

    private let dependencies: Dependencies
    private(set) var statusItem: NSStatusItem?

    public init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func start() {
        let item = dependencies.statusBar.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = Self.autosaveName
        let button = item.button!
        button.image = StatusIconRenderer.makeImage(description: dependencies.strings.calendar)
        button.toolTip = dependencies.strings.calendar
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        dependencies.launchAtLoginDefault.apply()
        dependencies.dayChanges.start { [weak self] in self?.dependencies.today.refreshToday() }
    }

    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        let presenter = dependencies.presenter
        if ClickClassifier.isSecondary(dependencies.events.currentEvent) {
            showMenu()
        } else if presenter.isShown {
            presenter.close()
        } else {
            dependencies.activator.activate(ignoringOtherApps: true)
            presenter.show(from: sender)
        }
    }

    @objc func toggleLaunchAtLogin() {
        let loginItem = dependencies.loginItem
        do {
            if loginItem.status == .enabled {
                try loginItem.unregister()
            } else {
                try loginItem.register()
            }
        } catch {
            dependencies.errorPresenter.present(error)
        }
    }

    private func showMenu() {
        dependencies.presenter.close()
        let menu = StatusMenuFactory.make(strings: dependencies.strings,
                                          launchAtLoginEnabled: dependencies.loginItem.status == .enabled,
                                          target: self, toggleLaunchAtLogin: #selector(toggleLaunchAtLogin))
        dependencies.menuPresenter.present(menu, on: statusItem!)
    }
}
