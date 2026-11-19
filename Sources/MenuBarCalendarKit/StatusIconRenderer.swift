import AppKit
import CalendarCore

/// Draws the menu bar icon as a template image, so macOS tints it for light and dark menu bars.
enum StatusIconRenderer {
    static func makeImage(description: String) -> NSImage {
        let image = NSImage(size: StatusIconShape.size, flipped: true) { _ in
            NSColor.black.setFill()
            CalendarGlyph.path().fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description
        return image
    }
}
