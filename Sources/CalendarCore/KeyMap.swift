import Foundation

/// A key press, reduced to what the calendar cares about.
public enum Key: Equatable {
    case left, right, up, down, pageUp, pageDown
    case other(String?)
}

/// What a key press should do.
public enum KeyAction: Equatable {
    case command(CalendarCommand)
    case dismiss
}

/// The calendar's keyboard shortcuts.
public enum KeyMap {
    public static func action(for key: Key) -> KeyAction? {
        switch key {
        case .left: return .command(.moveSelection(days: -1))
        case .right: return .command(.moveSelection(days: 1))
        case .up: return .command(.moveSelection(days: -7))
        case .down: return .command(.moveSelection(days: 7))
        case .pageUp: return .command(.step(-1))
        case .pageDown: return .command(.step(1))
        case .other(let characters): return action(forCharacters: characters?.lowercased())
        }
    }

    private static func action(forCharacters characters: String?) -> KeyAction? {
        switch characters {
        case "\u{1b}": return .dismiss
        default: return nil
        }
    }
}
