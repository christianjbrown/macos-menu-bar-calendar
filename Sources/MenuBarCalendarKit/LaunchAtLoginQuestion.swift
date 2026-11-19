import AppKit
import CalendarCore

/// Asks the user whether the app should open at login.
@MainActor
public protocol LaunchAtLoginAsking: AnyObject {
    /// True when the user said yes.
    func askToLaunchAtLogin() -> Bool
}

/// Asks in a modal alert, with Yes as the default button and No on Escape.
@MainActor
public final class AlertLaunchAtLoginQuestion: LaunchAtLoginAsking {
    static let escapeKeyEquivalent = "\u{1b}"

    private let strings: AppStrings
    private let activator: AppActivating

    public init(strings: AppStrings, activator: AppActivating) {
        self.strings = strings
        self.activator = activator
    }

    public func askToLaunchAtLogin() -> Bool {
        // A menu bar app is never frontmost on its own, so the alert would open behind other windows.
        activator.activate(ignoringOtherApps: true)
        return Self.isYes(makeAlert().runModal())
    }

    func makeAlert() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = strings.launchAtLoginQuestion
        alert.informativeText = strings.launchAtLoginQuestionDetail
        alert.addButton(withTitle: strings.yes)
        alert.addButton(withTitle: strings.no).keyEquivalent = Self.escapeKeyEquivalent
        return alert
    }

    static func isYes(_ response: NSApplication.ModalResponse) -> Bool {
        response == .alertFirstButtonReturn
    }
}
