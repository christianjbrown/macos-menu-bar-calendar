import Foundation

/// The current time, injectable so tests can pick the date.
public protocol Clock {
    func now() -> Date
}

public struct SystemClock: Clock {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
