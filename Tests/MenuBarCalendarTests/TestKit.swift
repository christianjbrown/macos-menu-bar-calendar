import AppKit
import CalendarCore

// A tiny test harness. XCTest and Swift Testing do not build with the Command Line
// Tools alone, so tests are plain functions registered in suites and run by main.swift.

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

@MainActor
final class TestRun {
    static let shared = TestRun()
    private(set) var passed = 0
    private(set) var failures: [String] = []

    func run(_ suite: String, _ name: String, _ body: () throws -> Void) {
        do {
            try body()
            passed += 1
        } catch {
            failures.append("\(suite) - \(name): \(error)")
        }
    }
}

func expect(_ condition: Bool, _ message: @autoclosure () -> String = "expectation failed",
            file: StaticString = #fileID, line: UInt = #line) throws {
    if !condition {
        throw TestFailure(description: "\(file):\(line) \(message())")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ note: String = "",
                               file: StaticString = #fileID, line: UInt = #line) throws {
    try expect(actual == expected, "expected \(expected), got \(actual) \(note)", file: file, line: line)
}

/// Lets queued main-queue work and timers run.
@MainActor
func spinRunLoop(_ seconds: TimeInterval = 0.05) {
    RunLoop.main.run(until: Date().addingTimeInterval(seconds))
}

func gregorian(firstWeekday: Int = 2) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/London")!
    calendar.locale = Locale(identifier: "en_GB")
    calendar.firstWeekday = firstWeekday
    return calendar
}

func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    gregorian().date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

// MARK: Event builders

func keyEvent(_ characters: String) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
                     context: nil, characters: characters, charactersIgnoringModifiers: characters,
                     isARepeat: false, keyCode: 0)!
}

func mouseEvent(_ type: NSEvent.EventType, at point: NSPoint = .zero, in window: NSWindow? = nil,
                modifiers: NSEvent.ModifierFlags = []) -> NSEvent {
    NSEvent.mouseEvent(with: type, location: point, modifierFlags: modifiers, timestamp: 0,
                       windowNumber: window?.windowNumber ?? 0, context: nil, eventNumber: 0,
                       clickCount: 1, pressure: 1)!
}

func exitEvent(in window: NSWindow) -> NSEvent {
    NSEvent.enterExitEvent(with: .mouseExited, location: .zero, modifierFlags: [], timestamp: 0,
                           windowNumber: window.windowNumber, context: nil, eventNumber: 0,
                           trackingNumber: 0, userData: nil)!
}

func scrollEvent(lines: Int32 = 0, pixels: Int32 = 0, phase: Int64 = 0, momentumPhase: Int64 = 0) -> NSEvent {
    let precise = pixels != 0
    let event = CGEvent(scrollWheelEvent2Source: nil, units: precise ? .pixel : .line, wheelCount: 1,
                        wheel1: precise ? pixels : lines, wheel2: 0, wheel3: 0)!
    event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
    event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentumPhase)
    return NSEvent(cgEvent: event)!
}

/// A borderless window that hosts a view so coordinates and responders behave as in the app.
@MainActor
func hostWindow(for view: NSView, size: NSSize) -> NSWindow {
    let window = NSWindow(contentRect: NSRect(origin: NSPoint(x: 200, y: 200), size: size),
                          styleMask: [.borderless], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = view
    return window
}
