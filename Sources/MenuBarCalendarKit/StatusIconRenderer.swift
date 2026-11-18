import AppKit
import CalendarCore

/// Draws the menu bar icon as a template image, so macOS tints it for light and dark menu bars.
enum StatusIconRenderer {
    static func makeImage(description: String) -> NSImage {
        let image = NSImage(size: StatusIconShape.size, flipped: true) { _ in
            draw()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = description
        return image
    }

    private static func draw() {
        NSColor.black.setFill()
        let page = NSBezierPath(roundedRect: StatusIconShape.page,
                                xRadius: StatusIconShape.pageRadius, yRadius: StatusIconShape.pageRadius)
        page.append(NSBezierPath(roundedRect: StatusIconShape.window,
                                 xRadius: StatusIconShape.windowRadius, yRadius: StatusIconShape.windowRadius))
        page.windingRule = .evenOdd
        page.fill()
        for dot in StatusIconShape.dots {
            NSBezierPath(roundedRect: dot, xRadius: StatusIconShape.dotRadius, yRadius: StatusIconShape.dotRadius).fill()
        }
    }
}
