import AppKit
import CalendarCore
import ServiceManagement

/// The composition root: the one place that picks the real system services.
@MainActor
public enum AppComposition {
    public static func makeController() -> AppController {
        let strings = AppStrings.preferred(Locale.preferredLanguages)
        let loginItem = SMAppService.mainApp
        let errorPresenter = AlertErrorPresenter(title: strings.launchAtLoginFailed)
        let calendar = CalendarViewController(clock: SystemClock(), calendar: .autoupdatingCurrent, strings: strings)
        return AppController(dependencies: .init(
            strings: strings,
            statusBar: NSStatusBar.system,
            presenter: CalendarPopover(content: calendar),
            today: calendar,
            dayChanges: DayChangeObserver(center: .default, workspaceCenter: NSWorkspace.shared.notificationCenter),
            loginItem: loginItem,
            launchAtLoginPrompt: LaunchAtLoginPrompt(
                loginItem: loginItem, settings: UserDefaults.standard,
                question: AlertLaunchAtLoginQuestion(strings: strings, activator: NSApplication.shared),
                errorPresenter: errorPresenter),
            menuPresenter: StatusItemMenuPresenter(),
            errorPresenter: errorPresenter,
            events: NSApplication.shared,
            activator: NSApplication.shared
        ))
    }
}
