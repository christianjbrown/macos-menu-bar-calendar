import AppKit
import CalendarCore

extension Key {
    /// Reduces a key-down event to the keys the calendar understands.
    init(event: NSEvent) {
        switch event.specialKey {
        case .leftArrow?: self = .left
        case .rightArrow?: self = .right
        case .upArrow?: self = .up
        case .downArrow?: self = .down
        case .pageUp?: self = .pageUp
        case .pageDown?: self = .pageDown
        default: self = .other(event.charactersIgnoringModifiers)
        }
    }
}

/// Tells a right click (or control-click) on the status item from a plain click.
enum ClickClassifier {
    static func isSecondary(_ event: NSEvent?) -> Bool {
        guard let event else { return false }
        return event.type == .rightMouseUp || event.modifierFlags.contains(.control)
    }
}
