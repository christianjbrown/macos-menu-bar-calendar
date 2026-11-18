import AppKit
import CalendarCore
import ServiceManagement
@testable import MenuBarCalendarKit

struct FakeError: Error {}

final class FakeClock: Clock {
    var current: Date
    init(_ date: Date) { current = date }
    func now() -> Date { current }
}

@MainActor
final class FakeLoginItem: LoginItemService {
    var status: SMAppService.Status = .notRegistered
    var error: Error?
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0

    func register() throws {
        registerCount += 1
        if let error { throw error }
        status = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        if let error { throw error }
        status = .notRegistered
    }
}

final class FakeSettings: SettingsStore {
    var values: [String: Bool] = [:]
    func bool(forKey key: String) -> Bool { values[key] ?? false }
    func set(_ value: Bool, forKey key: String) { values[key] = value }
}

@MainActor
final class FakePresenter: CalendarPresenting {
    var isShown = false
    private(set) var shownFrom: NSView?
    private(set) var closeCount = 0
    func show(from view: NSView) { shownFrom = view; isShown = true }
    func close() { closeCount += 1; isShown = false }
}

@MainActor
final class FakeToday: TodayRefreshing {
    private(set) var refreshCount = 0
    func refreshToday() { refreshCount += 1 }
}

@MainActor
final class FakeDayChanges: DayChangeSource {
    private(set) var onChange: (@MainActor () -> Void)?
    func start(onChange: @escaping @MainActor () -> Void) { self.onChange = onChange }
}

@MainActor
final class FakeMenuPresenter: MenuPresenting {
    private(set) var menu: NSMenu?
    private(set) var item: NSStatusItem?
    func present(_ menu: NSMenu, on item: NSStatusItem) { self.menu = menu; self.item = item }
}

@MainActor
final class FakeErrorPresenter: ErrorPresenting {
    private(set) var errors: [Error] = []
    func present(_ error: Error) { errors.append(error) }
}

@MainActor
final class FakeEvents: EventSource {
    var currentEvent: NSEvent?
}

@MainActor
final class FakeActivator: AppActivating {
    private(set) var activations: [Bool] = []
    func activate(ignoringOtherApps flag: Bool) { activations.append(flag) }
}

@MainActor
final class FakeApplication: ApplicationRunning {
    var delegate: NSApplicationDelegate?
    private(set) var policy: NSApplication.ActivationPolicy?
    private(set) var didRun = false
    func setActivationPolicy(_ activationPolicy: NSApplication.ActivationPolicy) -> Bool {
        policy = activationPolicy
        return true
    }
    func run() { didRun = true }
}

@MainActor
final class FakeDismisser: CalendarDismissing {
    private(set) var closeCount = 0
    func close() { closeCount += 1 }
}

@MainActor
final class FakeGridDelegate: CalendarGridViewDelegate {
    var handles = true
    private(set) var commands: [CalendarCommand] = []
    private(set) var keys: [Key] = []
    private(set) var scrolled: [Int] = []
    func gridView(_ gridView: CalendarGridView, didRequest command: CalendarCommand) { commands.append(command) }
    func gridView(_ gridView: CalendarGridView, handle key: Key) -> Bool { keys.append(key); return handles }
    func gridView(_ gridView: CalendarGridView, didScroll steps: Int) { scrolled.append(steps) }
}

/// Catches keys that the grid passes up the responder chain.
final class KeyCatcher: NSResponder {
    private(set) var caught = 0
    override func keyDown(with event: NSEvent) { caught += 1 }
}

