import Foundation

/// One cell of the month or year picker.
public struct PickerItem: Equatable {
    public let label: String
    public let command: CalendarCommand
    /// Contains today, so it gets the today highlight.
    public let isCurrent: Bool
    /// The month or year the user came from, so it gets the outline.
    public let isSelected: Bool

    public init(label: String, command: CalendarCommand, isCurrent: Bool, isSelected: Bool) {
        self.label = label
        self.command = command
        self.isCurrent = isCurrent
        self.isSelected = isSelected
    }
}

/// The twelve months of a year, or a page of twelve years, laid out four across and three down.
public struct PickerGrid: Equatable {
    public static let columns = 4
    public static let rows = 3

    public let items: [PickerItem]

    public static func months(of year: Int, displayed: Month, today: Day, calendar: Calendar) -> PickerGrid {
        let symbols = calendar.shortStandaloneMonthSymbols
        return PickerGrid(items: (1...12).map { number in
            let month = Month(year: year, month: number)
            return PickerItem(label: symbols[number - 1], command: .pickMonth(month),
                              isCurrent: month.contains(today), isSelected: month == displayed)
        })
    }

    public static func years(_ years: Range<Int>, displayed: Int, today: Day) -> PickerGrid {
        PickerGrid(items: years.map { year in
            PickerItem(label: "\(year)", command: .pickYear(year),
                       isCurrent: year == today.year, isSelected: year == displayed)
        })
    }
}

/// What the grid area shows for the current zoom level.
public enum CalendarPage: Equatable {
    case days(MonthGrid, today: Day, selected: Day)
    case picker(PickerGrid)

    public init(state: CalendarState, calendar: Calendar) {
        switch state.mode {
        case .days:
            self = .days(MonthGrid(month: state.month, calendar: calendar), today: state.today, selected: state.selected)
        case .months:
            self = .picker(.months(of: state.month.year, displayed: state.month, today: state.today, calendar: calendar))
        case .years:
            self = .picker(.years(state.years, displayed: state.month.year, today: state.today))
        }
    }

    /// What clicking the cell at an index does.
    public func command(at index: Int) -> CalendarCommand {
        switch self {
        case .days(let grid, _, _): return .select(grid.days[index])
        case .picker(let picker): return picker.items[index].command
        }
    }
}

/// One clickable (or plain) piece of the header title.
public struct HeaderPart: Equatable {
    public let text: String
    public let command: CalendarCommand?

    public init(text: String, command: CalendarCommand?) {
        self.text = text
        self.command = command
    }
}

/// The header title for each zoom level: "November" "2026", then "2026", then "2021 - 2032".
public enum CalendarHeader {
    public static func parts(for state: CalendarState, calendar: Calendar) -> [HeaderPart] {
        let year = HeaderPart(text: "\(state.month.year)", command: .showYears)
        switch state.mode {
        case .days:
            let name = calendar.standaloneMonthSymbols[state.month.month - 1]
            return [HeaderPart(text: name, command: .showMonths), year]
        case .months:
            return [year]
        case .years:
            return [HeaderPart(text: "\(state.years.lowerBound) - \(state.years.upperBound - 1)", command: nil)]
        }
    }
}
