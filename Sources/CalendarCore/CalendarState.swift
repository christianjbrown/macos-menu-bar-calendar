import Foundation

/// Which zoom level the calendar is showing.
public enum CalendarMode: Equatable {
    /// The days of one month.
    case days
    /// The twelve months of one year.
    case months
    /// A page of twelve years.
    case years
}

/// Something the user asked the calendar to do.
public enum CalendarCommand: Equatable {
    /// Page back (negative) or forward: a month of days, a year of months, or six years.
    case step(Int)
    case moveSelection(days: Int)
    case select(Day)
    case showMonths
    case showYears
    case pickMonth(Month)
    case pickYear(Int)
}

/// What the calendar shows: the zoom level, the month on screen, today, and the selected day.
public struct CalendarState: Equatable {
    public static let yearsPerPage = 12
    public static let yearsBeforeDisplayed = 5
    public static let yearStep = 6

    public private(set) var mode: CalendarMode = .days
    public private(set) var month: Month
    public private(set) var today: Day
    public private(set) var selected: Day
    /// The first year on the years page.
    public private(set) var firstYear: Int

    public init(today: Day) {
        self.today = today
        selected = today
        month = Month(today)
        firstYear = today.year - Self.yearsBeforeDisplayed
    }

    public var years: Range<Int> {
        firstYear..<(firstYear + Self.yearsPerPage)
    }

    public mutating func apply(_ command: CalendarCommand, calendar: Calendar) {
        switch command {
        case .step(let count):
            step(count)
        case .moveSelection(let days):
            guard mode == .days else { return }
            select(selected.adding(days: days, calendar: calendar))
        case .select(let day):
            select(day)
        case .showMonths:
            mode = .months
        case .showYears:
            firstYear = month.year - Self.yearsBeforeDisplayed
            mode = .years
        case .pickMonth(let picked):
            month = picked
            mode = .days
        case .pickYear(let year):
            month = Month(year: year, month: month.month)
            mode = .months
        }
    }

    /// Moves "today" forward, and brings the selection along if it was sitting on today.
    public mutating func updateToday(_ day: Day) {
        let wasFollowingToday = selected == today
        today = day
        guard wasFollowingToday else { return }
        selected = day
        if mode == .days {
            month = Month(day)
        }
    }

    private mutating func step(_ count: Int) {
        switch mode {
        case .days: month = month.adding(months: count)
        case .months: month = month.adding(months: count * 12)
        case .years: firstYear += count * Self.yearStep
        }
    }

    private mutating func select(_ day: Day) {
        selected = day
        if !month.contains(day) {
            month = Month(day)
        }
    }
}
