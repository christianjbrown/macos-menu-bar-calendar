import Foundation

/// Turns scroll wheel and trackpad deltas into whole-month steps.
///
/// Trackpads send many small precise deltas, so they accumulate until they cross a
/// threshold. A mouse wheel sends one line per notch, which is one month each.
public struct ScrollStepper {
    public static let preciseThreshold = 30.0

    private var accumulated = 0.0

    public init() {}

    /// Returns how many months to move: negative for back in time (scrolling up).
    public mutating func consume(deltaY: Double, isPrecise: Bool, gestureEnded: Bool) -> Int {
        accumulated += deltaY
        let threshold = isPrecise ? Self.preciseThreshold : 1
        let steps = Int(accumulated / threshold)
        accumulated -= Double(steps) * threshold
        if gestureEnded {
            accumulated = 0
        }
        return -steps
    }
}
