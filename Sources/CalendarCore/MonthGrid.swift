import Foundation

/// The 6 x 7 block of days shown for one month, starting on the calendar's first weekday.
public struct MonthGrid: Equatable {
    public static let rows = 6
    public static let columns = 7

    public let month: Month
    public let days: [Day]
    /// Very short weekday names in display order, for the column headers.
    public let weekdaySymbols: [String]

    public init(month: Month, calendar: Calendar) {
        self.month = month
        let first = month.firstDay
        let weekday = calendar.component(.weekday, from: first.date(in: calendar))
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let start = first.adding(days: -leading, calendar: calendar)
        days = (0..<(Self.rows * Self.columns)).map { start.adding(days: $0, calendar: calendar) }

        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        weekdaySymbols = (0..<Self.columns).map { symbols[(calendar.firstWeekday - 1 + $0) % Self.columns] }
    }
}
