import AppKit
import CalendarCore

/// Maps a cell's style to colours and fonts. Every colour is a system colour or a
/// light and dark pair, so drawing follows the system theme.
enum Palette {
    /// The accent used for today, with separate shades for light and dark mode.
    static let today = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(srgbRed: 0.20, green: 0.55, blue: 0.90, alpha: 1)
            : NSColor(srgbRed: 0.25, green: 0.60, blue: 1.00, alpha: 1)
    }

    static let outline = NSColor.secondaryLabelColor
    static let separator = NSColor.separatorColor
    static let header = NSColor.secondaryLabelColor
    static let headerFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let titleFont = NSFont.systemFont(ofSize: 13, weight: .semibold)

    static func background(_ background: CellStyle.Background) -> NSColor? {
        switch background {
        case .none: return nil
        case .today: return today
        case .hover: return .quaternaryLabelColor
        }
    }

    static func textColor(_ text: CellStyle.Text) -> NSColor {
        switch text {
        case .today: return .white
        case .current: return .labelColor
        case .adjacent: return .tertiaryLabelColor
        }
    }

    static func font(_ text: CellStyle.Text, size: CGFloat) -> NSFont {
        NSFont.monospacedDigitSystemFont(ofSize: size, weight: text == .today ? .semibold : .regular)
    }
}
