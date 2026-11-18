import Foundation

/// A month, identified by year and month number.
public struct Month: Hashable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(_ day: Day) {
        self.init(year: day.year, month: day.month)
    }

    public var firstDay: Day {
        Day(year: year, month: month, day: 1)
    }

    public func adding(months count: Int) -> Month {
        let index = year * 12 + (month - 1) + count
        return Month(year: Int(floor(Double(index) / 12)), month: ((index % 12) + 12) % 12 + 1)
    }

    public func contains(_ day: Day) -> Bool {
        day.year == year && day.month == month
    }
}
