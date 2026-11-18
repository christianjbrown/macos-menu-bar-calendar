import Foundation

/// A calendar day without a time or time zone, so comparisons never drift.
public struct Day: Hashable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    /// Midday on this day, which is safely inside the day whatever the clocks do.
    public func date(in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    public func adding(days count: Int, calendar: Calendar) -> Day {
        Day(calendar.date(byAdding: .day, value: count, to: date(in: calendar))!, calendar: calendar)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
