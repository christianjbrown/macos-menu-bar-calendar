import AppKit
import CalendarCore

/// The calendar page both icons draw: the page outline with its header band, and the dots.
/// One even-odd path, so the window is a hole and the dots inside it fill again.
enum CalendarGlyph {
    static func path() -> NSBezierPath {
        let path = NSBezierPath(roundedRect: StatusIconShape.page,
                                xRadius: StatusIconShape.pageRadius, yRadius: StatusIconShape.pageRadius)
        path.append(NSBezierPath(roundedRect: StatusIconShape.window,
                                 xRadius: StatusIconShape.windowRadius, yRadius: StatusIconShape.windowRadius))
        for dot in StatusIconShape.dots {
            path.append(NSBezierPath(roundedRect: dot, xRadius: StatusIconShape.dotRadius, yRadius: StatusIconShape.dotRadius))
        }
        path.windingRule = .evenOdd
        return path
    }
}
